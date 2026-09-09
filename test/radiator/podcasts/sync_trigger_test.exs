defmodule Radiator.Podcasts.SyncTriggerTest do
  use Radiator.DataCase, async: false

  require Ash.Query

  # Failing jobs are the point of several of these; their logs are not.
  @moduletag :capture_log

  alias Radiator.FeedFixtures
  alias Radiator.Feeds.Response
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Podcast
  alias Radiator.StubFeedClient

  setup do
    StubFeedClient.reset()
    StubFeedClient.put(ok_response())

    %{user: generate(user())}
  end

  defp ok_response do
    {:ok,
     %Response{
       status: 200,
       body: FeedFixtures.read!("minimal.xml"),
       etag: ~s("v1"),
       final_url: "https://example.com/feed"
     }}
  end

  # The scheduler runs in the trigger's own queue (`scheduler_queue` defaults to
  # `queue`), so draining counts its job as a success too. Job counts are
  # therefore not a reliable signal; these tests assert on state instead.
  defp run_triggers, do: AshOban.Test.schedule_and_run_triggers({Podcast, :sync})

  defp reload(podcast), do: Ash.get!(Podcast, podcast.id)

  defp sync_job do
    Oban.Job
    |> where([j], j.worker == "Radiator.Podcasts.Workers.SyncFeed")
    |> Repo.one!()
  end

  test "the cron does not enqueue a second job for a podcast already queued", %{user: user} do
    StubFeedClient.put({:error, :timeout})
    Podcasts.import_podcast!(%{feed_url: "https://example.com/slow"}, actor: user)

    run_triggers()

    # `Repo.one!/1` would raise on a second row. The immediate job carries the
    # acting user and the cron's does not, so without per-record uniqueness the
    # differing args let both through.
    assert sync_job().state == "retryable"
  end

  test "a pending podcast is picked up and imported", %{user: user} do
    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/feed"}, actor: user)

    run_triggers()

    synced = reload(podcast)
    assert synced.sync_status == :succeeded
    assert synced.title == "Test Show"

    assert Episode |> Ash.Query.filter(podcast_id == ^podcast.id) |> Ash.read!() |> length() == 5
  end

  test "an idle podcast is left alone", %{user: user} do
    podcast =
      Podcasts.create_podcast!(
        %{title: "By hand", feed_url: "https://example.com/feed"},
        actor: user
      )

    run_triggers()

    assert reload(podcast).sync_status == :idle
    assert reload(podcast).title == "By hand"
  end

  test "a podcast without a feed url is left alone", %{user: user} do
    podcast = Podcasts.create_podcast!(%{title: "No feed"}, actor: user)

    run_triggers()

    assert reload(podcast).sync_status == :idle
  end

  test "a succeeded podcast is not picked up again", %{user: user} do
    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/feed"}, actor: user)
    run_triggers()
    first = reload(podcast)

    run_triggers()

    assert reload(podcast).last_checked_at == first.last_checked_at
  end

  test "a scheduled podcast becomes due again once its check ages", %{user: user} do
    podcast =
      Podcasts.import_podcast!(
        %{feed_url: "https://example.com/feed", sync_strategy: :scheduled},
        actor: user
      )

    run_triggers()

    podcast
    |> reload()
    |> Ash.Changeset.for_update(:update, %{})
    |> Ash.Changeset.force_change_attribute(
      :last_checked_at,
      DateTime.add(DateTime.utc_now(), -2, :hour)
    )
    |> Ash.update!()

    run_triggers()

    assert DateTime.diff(DateTime.utc_now(), reload(podcast).last_checked_at, :second) < 5
  end

  test "a manual podcast never becomes due on its own", %{user: user} do
    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/feed"}, actor: user)
    run_triggers()

    stale = DateTime.add(DateTime.utc_now(), -2, :hour)

    podcast
    |> reload()
    |> Ash.Changeset.for_update(:update, %{})
    |> Ash.Changeset.force_change_attribute(:last_checked_at, stale)
    |> Ash.update!()

    run_triggers()

    assert DateTime.compare(reload(podcast).last_checked_at, stale) == :eq
  end

  test "request_sync makes it eligible again", %{user: user} do
    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/feed"}, actor: user)
    run_triggers()
    first = reload(podcast)

    Podcasts.request_sync!(first)
    run_triggers()

    assert DateTime.compare(reload(podcast).last_checked_at, first.last_checked_at) == :gt
  end

  test "a rate limited feed is rescheduled for the delay the server asked for", %{user: user} do
    StubFeedClient.put({:error, {:http_status, 429, 120}})
    Podcasts.import_podcast!(%{feed_url: "https://example.com/busy"}, actor: user)

    run_triggers()

    job = sync_job()

    assert job.state == "retryable"
    assert_in_delta DateTime.diff(job.scheduled_at, DateTime.utc_now()), 120, 15
  end

  test "a transient failure without a Retry-After backs off exponentially", %{user: user} do
    StubFeedClient.put({:error, :timeout})
    Podcasts.import_podcast!(%{feed_url: "https://example.com/slow"}, actor: user)

    run_triggers()

    job = sync_job()

    assert job.state == "retryable"
    assert_in_delta DateTime.diff(job.scheduled_at, DateTime.utc_now()), 16, 15
  end

  test "a manual sync cancels a waiting retry and runs right away", %{user: user} do
    StubFeedClient.put({:error, {:http_status, 503, 900}})
    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/busy"}, actor: user)
    run_triggers()

    waiting = sync_job()
    assert waiting.state == "retryable"

    StubFeedClient.put(ok_response())
    Podcasts.request_sync!(reload(podcast))

    jobs = Repo.all(where(Oban.Job, [j], j.worker == "Radiator.Podcasts.Workers.SyncFeed"))
    assert Enum.map(jobs, & &1.state) |> Enum.sort() == ["available", "cancelled"]
    assert Enum.find(jobs, &(&1.id == waiting.id)).state == "cancelled"

    run_triggers()

    assert reload(podcast).sync_status == :succeeded
  end

  test "a permanent failure completes the job instead of retrying it", %{user: user} do
    StubFeedClient.put({:error, {:http_status, 404}})
    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/gone"}, actor: user)

    run_triggers()

    assert %{state: "completed", attempt: 1} = sync_job()

    failed = reload(podcast)
    assert failed.sync_status == :failed
    assert failed.last_sync_error =~ "404"
    assert failed.last_checked_at != nil
  end

  test "a permanently failed podcast is not picked up again", %{user: user} do
    StubFeedClient.put({:error, {:http_status, 404}})
    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/gone"}, actor: user)
    run_triggers()
    first = reload(podcast)

    run_triggers()

    assert reload(podcast).last_checked_at == first.last_checked_at
  end
end
