defmodule Radiator.Podcasts.SyncTriggerTest do
  use Radiator.DataCase, async: false

  require Ash.Query

  # Failing jobs are the point of several of these; their logs are not.
  @moduletag :capture_log

  alias Radiator.Feeds.Client.ReqClient
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Podcast

  @worker "Radiator.Podcasts.Workers.SyncFeed"

  setup do
    Req.Test.stub(ReqClient, Radiator.FeedPlug)

    %{user: generate(user())}
  end

  # The path picks the response; see `Radiator.FeedPlug`.
  defp import!(user, path, attrs \\ %{}) do
    attrs
    |> Map.put(:feed_url, "https://example.com#{path}")
    |> Podcasts.import_podcast!(actor: user)
  end

  # The scheduler runs in the trigger's own queue (`scheduler_queue` defaults to
  # `queue`), so draining counts its job as a success too. Job counts are
  # therefore not a reliable signal; these tests assert on state instead.
  defp run_triggers, do: AshOban.Test.schedule_and_run_triggers({Podcast, :sync})

  # Reads stored state, not what a user may see; `:read` is owner-only.
  defp reload(podcast), do: Ash.get!(Podcast, podcast.id, authorize?: false)

  defp sync_jobs, do: Repo.all(where(Oban.Job, [j], j.worker == @worker))

  defp sync_job, do: Repo.one!(where(Oban.Job, [j], j.worker == @worker))

  defp age_check!(podcast, hours, user) do
    podcast
    |> reload()
    |> Ash.Changeset.for_update(:update, %{}, actor: user)
    |> Ash.Changeset.force_change_attribute(
      :last_checked_at,
      DateTime.add(DateTime.utc_now(), -hours, :hour)
    )
    |> Ash.update!()
  end

  test "the cron does not enqueue a second job for a podcast already queued", %{user: user} do
    import!(user, "/slow")

    run_triggers()

    # `Repo.one!/1` would raise on a second row.
    assert sync_job().state == "retryable"
  end

  test "a pending podcast is picked up and imported", %{user: user} do
    podcast = import!(user, "/feed")

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

    assert %{sync_status: :idle, title: "By hand"} = reload(podcast)
  end

  test "a podcast without a feed url is left alone", %{user: user} do
    podcast = Podcasts.create_podcast!(%{title: "No feed"}, actor: user)

    run_triggers()

    assert reload(podcast).sync_status == :idle
  end

  test "a succeeded podcast is not picked up again", %{user: user} do
    podcast = import!(user, "/feed")
    run_triggers()
    first = reload(podcast)

    run_triggers()

    assert reload(podcast).last_checked_at == first.last_checked_at
  end

  test "a scheduled podcast becomes due again once its check ages", %{user: user} do
    podcast = import!(user, "/feed", %{sync_strategy: :scheduled})
    run_triggers()

    age_check!(podcast, 2, user)
    run_triggers()

    assert DateTime.diff(DateTime.utc_now(), reload(podcast).last_checked_at, :second) < 5
  end

  test "a manual podcast never becomes due on its own", %{user: user} do
    podcast = import!(user, "/feed")
    run_triggers()

    stale = age_check!(podcast, 2, user).last_checked_at
    run_triggers()

    assert DateTime.compare(reload(podcast).last_checked_at, stale) == :eq
  end

  test "request_sync makes it eligible again", %{user: user} do
    podcast = import!(user, "/feed")
    run_triggers()
    first = reload(podcast)

    Podcasts.request_sync!(first, %{}, actor: user)
    run_triggers()

    assert DateTime.compare(reload(podcast).last_checked_at, first.last_checked_at) == :gt
  end

  test "a rate limited feed is rescheduled for the delay the server asked for", %{user: user} do
    import!(user, "/busy")

    run_triggers()

    job = sync_job()

    assert job.state == "retryable"
    assert_in_delta DateTime.diff(job.scheduled_at, DateTime.utc_now()), 120, 15
  end

  test "a transient failure without a Retry-After backs off exponentially", %{user: user} do
    import!(user, "/slow")

    run_triggers()

    job = sync_job()

    assert job.state == "retryable"
    assert_in_delta DateTime.diff(job.scheduled_at, DateTime.utc_now()), 16, 15
  end

  test "a manual sync cancels a waiting retry and runs right away", %{user: user} do
    podcast = import!(user, "/unavailable")
    run_triggers()

    waiting = sync_job()
    assert waiting.state == "retryable"

    podcast
    |> reload()
    |> Ash.update!(%{feed_url: "https://example.com/feed"}, actor: user)
    |> Podcasts.request_sync!(%{}, actor: user)

    jobs = sync_jobs()
    assert jobs |> Enum.map(& &1.state) |> Enum.sort() == ["available", "cancelled"]
    assert Enum.find(jobs, &(&1.id == waiting.id)).state == "cancelled"

    run_triggers()

    assert reload(podcast).sync_status == :succeeded
  end

  test "a permanent failure completes the job instead of retrying it", %{user: user} do
    podcast = import!(user, "/gone")

    run_triggers()

    assert %{state: "completed", attempt: 1} = sync_job()

    failed = reload(podcast)
    assert failed.sync_status == :failed
    assert failed.last_sync_error =~ "404"
    assert failed.last_checked_at != nil
  end

  test "a permanently failed podcast is not picked up again", %{user: user} do
    podcast = import!(user, "/gone")
    run_triggers()
    first = reload(podcast)

    run_triggers()

    assert reload(podcast).last_checked_at == first.last_checked_at
  end
end
