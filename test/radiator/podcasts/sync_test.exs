defmodule Radiator.Podcasts.SyncTest do
  use Radiator.DataCase, async: true

  require Ash.Query

  alias Radiator.Feeds.Client.ReqClient
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.FeedSyncError
  alias Radiator.Podcasts.Podcast

  setup do
    Req.Test.stub(ReqClient, Radiator.FeedPlug)

    %{user: generate(user())}
  end

  # The path picks the response; see `Radiator.FeedPlug`.
  defp import!(user, path) do
    Podcasts.import_podcast!(%{feed_url: "https://example.com#{path}"}, actor: user)
  end

  # Stands in for the Oban worker, which runs `:sync` without an actor.
  defp sync!(podcast), do: Ash.update!(podcast, %{}, action: :sync, authorize?: false)

  defp episode_count(podcast) do
    Episode |> Ash.Query.filter(podcast_id == ^podcast.id) |> Ash.read!() |> length()
  end

  describe "successful sync" do
    test "fetches, parses and writes", %{user: user} do
      synced = user |> import!("/feed") |> sync!()

      assert synced.title == "Test Show"
      assert synced.sync_status == :succeeded
      assert episode_count(synced) == 5
    end

    test "stores the http validators for the next run", %{user: user} do
      synced = user |> import!("/feed") |> sync!()

      assert synced.http_etag == ~s("v1")
      assert synced.http_last_modified == "Fri, 28 Aug 2026 17:14:26 GMT"
    end
  end

  describe "not modified" do
    test "the second run sends the validators, gets a 304 and leaves the episodes alone", %{
      user: user
    } do
      imported = user |> import!("/feed") |> sync!()
      checked = sync!(imported)

      assert checked.sync_status == :succeeded
      assert checked.last_imported_at == imported.last_imported_at
      assert DateTime.compare(checked.last_checked_at, imported.last_checked_at) == :gt
      assert episode_count(checked) == 5
    end

    test "a requested sync drops the validators so the server cannot answer 304", %{
      user: user
    } do
      imported = user |> import!("/feed") |> sync!()
      requested = Podcasts.request_sync!(imported, %{}, actor: user)

      assert requested.http_etag == nil
      assert requested.http_last_modified == nil

      synced = sync!(requested)

      assert DateTime.compare(synced.last_imported_at, imported.last_imported_at) == :gt
    end
  end

  describe "transient failures" do
    test "a timeout surfaces as an error and leaves the status alone", %{user: user} do
      podcast = import!(user, "/slow")

      assert {:error, error} = Ash.update(podcast, %{}, action: :sync, authorize?: false)
      assert FeedSyncError.summarize(error) =~ "timeout"
      assert Ash.get!(Podcast, podcast.id).sync_status == :pending
    end

    test "a 429 carries its Retry-After along", %{user: user} do
      podcast = import!(user, "/busy")

      assert {:error, %{errors: [%FeedSyncError{retry_after: 120}]}} =
               Ash.update(podcast, %{}, action: :sync, authorize?: false)
    end

    test "malformed xml is transient, because that is what a truncated body looks like", %{
      user: user
    } do
      podcast = import!(user, "/truncated")

      assert {:error, %{errors: [%FeedSyncError{}]}} =
               Ash.update(podcast, %{}, action: :sync, authorize?: false)

      assert Ash.get!(Podcast, podcast.id).sync_status == :pending
    end
  end

  describe "permanent failures" do
    test "404 is recorded as the outcome of the sync, not as an error", %{user: user} do
      assert {:ok, synced} =
               user |> import!("/gone") |> Ash.update(%{}, action: :sync, authorize?: false)

      assert synced.sync_status == :failed
      assert synced.last_sync_error =~ "404"
      assert synced.last_checked_at != nil
    end

    test "an HTML page instead of a feed is permanent", %{user: user} do
      synced = user |> import!("/html") |> sync!()

      assert synced.sync_status == :failed
      assert synced.last_sync_error =~ "text/html"
    end

    test "a document that is well-formed but not a feed is permanent", %{user: user} do
      assert %{sync_status: :failed} = user |> import!("/not-a-feed") |> sync!()
    end

    test "leaves the previous import untouched", %{user: user} do
      imported = user |> import!("/feed") |> sync!()

      failed =
        imported
        |> Ash.update!(%{feed_url: "https://example.com/gone"}, actor: user)
        |> sync!()

      assert failed.sync_status == :failed
      assert failed.last_imported_at == imported.last_imported_at
      assert failed.title == "Test Show"
      assert episode_count(failed) == 5
    end
  end
end
