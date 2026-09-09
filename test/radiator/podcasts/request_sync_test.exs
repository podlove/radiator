defmodule Radiator.Podcasts.RequestSyncTest do
  use Radiator.DataCase, async: true
  use AshOban.Test, repo: Radiator.Repo

  alias Radiator.Podcasts

  @with_feed %{title: "Test Show", feed_url: "https://example.com/feed"}

  setup do
    %{user: generate(user())}
  end

  describe "import" do
    test "marks the podcast as pending and enqueues the job", %{user: user} do
      podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/feed"}, actor: user)

      assert podcast.sync_status == :pending
      assert podcast.sync_strategy == :manual
      # The trigger tests cannot tell this apart from the cron finding a
      # pending record; only the enqueued job proves `run_oban_trigger` ran.
      assert_triggered(podcast, :sync)
    end

    test "takes the sync strategy", %{user: user} do
      podcast =
        Podcasts.import_podcast!(
          %{feed_url: "https://example.com/feed", sync_strategy: :scheduled},
          actor: user
        )

      assert podcast.sync_strategy == :scheduled
    end
  end

  describe "create" do
    test "leaves a hand-created podcast at idle so no cron picks it up", %{user: user} do
      podcast =
        Podcasts.create_podcast!(
          %{title: "By hand", feed_url: "https://example.com/feed"},
          actor: user
        )

      assert podcast.sync_status == :idle
    end
  end

  describe "request_sync" do
    test "moves the podcast back to pending and enqueues the job", %{user: user} do
      podcast = Podcasts.create_podcast!(@with_feed, actor: user)

      requested = Podcasts.request_sync!(podcast)

      assert requested.sync_status == :pending
      assert_triggered(requested, :sync)
    end

    test "works from a failed state", %{user: user} do
      podcast =
        @with_feed
        |> Podcasts.create_podcast!(actor: user)
        |> Ash.update!(%{error: :timeout}, action: :mark_sync_failed)

      assert Podcasts.request_sync!(podcast).sync_status == :pending
    end

    test "refuses a podcast without a feed url instead of parking it on pending", %{user: user} do
      podcast = Podcasts.create_podcast!(%{title: "No feed"}, actor: user)

      assert {:error, %Ash.Error.Invalid{}} = Podcasts.request_sync(podcast)
      assert Ash.get!(Radiator.Podcasts.Podcast, podcast.id).sync_status == :idle
    end
  end

  describe "update" do
    test "accepts a change of sync strategy", %{user: user} do
      podcast = Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)

      assert Ash.update!(podcast, %{sync_strategy: :scheduled}).sync_strategy == :scheduled
    end

    test "clears the http validators when the feed url changes", %{user: user} do
      podcast =
        %{title: "Test Show", feed_url: "https://example.com/a"}
        |> Podcasts.create_podcast!(actor: user)
        |> Ash.Changeset.for_update(:update, %{})
        |> Ash.Changeset.force_change_attribute(:http_etag, ~s("v1"))
        |> Ash.Changeset.force_change_attribute(:http_last_modified, "yesterday")
        |> Ash.update!()

      moved = Ash.update!(podcast, %{feed_url: "https://example.com/b"})

      assert moved.http_etag == nil
      assert moved.http_last_modified == nil
    end

    test "keeps the validators when the feed url stays put", %{user: user} do
      podcast =
        %{title: "Test Show", feed_url: "https://example.com/a"}
        |> Podcasts.create_podcast!(actor: user)
        |> Ash.Changeset.for_update(:update, %{})
        |> Ash.Changeset.force_change_attribute(:http_etag, ~s("v1"))
        |> Ash.update!()

      assert Ash.update!(podcast, %{title: "Renamed"}).http_etag == ~s("v1")
    end
  end
end
