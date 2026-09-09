defmodule Radiator.Podcasts.SyncTest do
  use Radiator.DataCase, async: true

  require Ash.Query

  alias Radiator.FeedFixtures
  alias Radiator.Feeds.Response
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.FeedSyncError
  alias Radiator.StubFeedClient

  setup do
    StubFeedClient.reset()
    user = generate(user())

    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/feed"}, actor: user)

    %{user: user, podcast: podcast}
  end

  defp ok_response(opts \\ []) do
    {:ok,
     %Response{
       status: 200,
       body: FeedFixtures.read!("minimal.xml"),
       etag: Keyword.get(opts, :etag, ~s("v1")),
       last_modified: Keyword.get(opts, :last_modified, "Fri, 28 Aug 2026 17:14:26 GMT"),
       final_url: "https://example.com/feed"
     }}
  end

  defp episode_count(podcast) do
    Episode |> Ash.Query.filter(podcast_id == ^podcast.id) |> Ash.read!() |> length()
  end

  describe "successful sync" do
    test "fetches, parses and writes", %{podcast: podcast} do
      StubFeedClient.put(ok_response())

      synced = Ash.update!(podcast, %{}, action: :sync)

      assert synced.title == "Test Show"
      assert synced.sync_status == :succeeded
      assert episode_count(podcast) == 5
    end

    test "stores the http validators for the next run", %{podcast: podcast} do
      StubFeedClient.put(ok_response())

      synced = Ash.update!(podcast, %{}, action: :sync)

      assert synced.http_etag == ~s("v1")
      assert synced.http_last_modified == "Fri, 28 Aug 2026 17:14:26 GMT"
    end

    test "sends the stored validators on the following run", %{podcast: podcast} do
      StubFeedClient.put(ok_response())
      synced = Ash.update!(podcast, %{}, action: :sync)

      StubFeedClient.reset()
      StubFeedClient.put(ok_response(etag: ~s("v2")))
      Ash.update!(synced, %{}, action: :sync)

      assert [{"https://example.com/feed", opts}] = StubFeedClient.calls()
      assert opts[:etag] == ~s("v1")
      assert opts[:last_modified] == "Fri, 28 Aug 2026 17:14:26 GMT"
    end

    test "a requested sync drops the validators so the server cannot answer 304", %{
      podcast: podcast
    } do
      StubFeedClient.put(ok_response())
      synced = Ash.update!(podcast, %{}, action: :sync)

      requested = Podcasts.request_sync!(synced)

      assert requested.http_etag == nil
      assert requested.http_last_modified == nil

      StubFeedClient.reset()
      StubFeedClient.put(ok_response())
      Ash.update!(requested, %{}, action: :sync)

      assert [{_url, opts}] = StubFeedClient.calls()
      assert opts[:etag] == nil
    end
  end

  describe "not modified" do
    test "leaves the episodes alone and only moves last_checked_at", %{podcast: podcast} do
      StubFeedClient.put(ok_response())
      imported = Ash.update!(podcast, %{}, action: :sync)

      StubFeedClient.put({:not_modified, %Response{status: 304, etag: ~s("v1")}})
      checked = Ash.update!(imported, %{}, action: :sync)

      assert checked.sync_status == :succeeded
      assert checked.last_imported_at == imported.last_imported_at
      assert DateTime.compare(checked.last_checked_at, imported.last_checked_at) == :gt
      assert episode_count(podcast) == 5
    end
  end

  describe "transient failures" do
    test "a timeout surfaces as an error and leaves the status alone", %{podcast: podcast} do
      StubFeedClient.put({:error, :timeout})

      assert {:error, _error} = Ash.update(podcast, %{}, action: :sync)

      reloaded = Ash.get!(Radiator.Podcasts.Podcast, podcast.id)
      assert reloaded.sync_status == :pending
    end

    test "the error says what actually went wrong", %{podcast: podcast} do
      StubFeedClient.put({:error, :timeout})

      assert {:error, error} = Ash.update(podcast, %{}, action: :sync)
      assert FeedSyncError.summarize(error) == ":timeout"
    end

    test "a 429 carries its Retry-After along", %{podcast: podcast} do
      StubFeedClient.put({:error, {:http_status, 429, 120}})

      assert {:error, %{errors: [%FeedSyncError{retry_after: 120}]}} =
               Ash.update(podcast, %{}, action: :sync)
    end

    test "malformed xml is transient, because that is what a truncated body looks like", %{
      podcast: podcast
    } do
      StubFeedClient.put({:ok, %Response{status: 200, body: "<rss><channel>"}})

      assert {:error, %{errors: [%FeedSyncError{}]}} = Ash.update(podcast, %{}, action: :sync)

      reloaded = Ash.get!(Radiator.Podcasts.Podcast, podcast.id)
      assert reloaded.sync_status == :pending
    end
  end

  describe "permanent failures" do
    test "404 is recorded as the outcome of the sync, not as an error", %{podcast: podcast} do
      StubFeedClient.put({:error, {:http_status, 404}})

      assert {:ok, synced} = Ash.update(podcast, %{}, action: :sync)

      assert synced.sync_status == :failed
      assert synced.last_sync_error =~ "404"
      assert synced.last_checked_at != nil
    end

    test "a document that is well-formed but not a feed is permanent", %{podcast: podcast} do
      StubFeedClient.put({:ok, %Response{status: 200, body: "<html>nope</html>"}})

      assert {:ok, synced} = Ash.update(podcast, %{}, action: :sync)
      assert synced.sync_status == :failed
    end

    test "leaves the previous import untouched", %{podcast: podcast} do
      StubFeedClient.put(ok_response())
      imported = Ash.update!(podcast, %{}, action: :sync)

      StubFeedClient.put({:error, {:http_status, 410}})
      failed = Ash.update!(imported, %{}, action: :sync)

      assert failed.last_imported_at == imported.last_imported_at
      assert failed.title == "Test Show"
      assert episode_count(podcast) == 5
    end
  end
end
