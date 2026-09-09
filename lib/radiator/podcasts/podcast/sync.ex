defmodule Radiator.Podcasts.Podcast.Sync do
  @moduledoc """
  Feed reconciliation: attributes, actions and the Oban trigger.

  ## Flow

  `:import` and `:request_sync` put the podcast on `:pending` and enqueue the
  trigger. The worker runs `:sync`: `FetchFeed` loads the feed in a
  `before_transaction` hook, so no network round trip holds a database
  transaction open, and `ApplyFeed` writes it in `before_action`. A permanent
  failure is a *result* of the sync (status `:failed`); a transient one fails
  the action and Oban retries it, and after the last attempt `on_error` runs
  `:mark_sync_failed`.

  Two timestamps, not one: `last_checked_at` moves on every check, a 304
  included. `last_imported_at` only moves on an actual import, and only it is
  compared against `Episode.last_seen_in_feed_at` — otherwise every 304 would
  make all episodes look as if they had vanished from the feed.

  ## AshOban details this module depends on

  * Worker jobs are unique over their whole args map. `run_oban_trigger`
    carries the actor and the cron does not, so both would be inserted without
    `unique: [keys: [:primary_key]]`.
  * `max_attempts` defaults to 1, and `backoff` is only consulted above 1.
  * `on_error` is called with `%{error: error}`. Without the declared argument
    the message is silently dropped. `require_atomic? false` is needed because
    `RecordSyncError` has no `atomic/3`, and Ash raising `MustBeAtomic` inside
    the error handler would swallow the original error along with it.
  * `run_oban_trigger` enqueues from `after_action`, inside the transaction.
    `CancelWaitingSyncJobs` has to run ahead of it in `before_action`, and a
    hook returned from `atomic/3` would not run at all — hence
    `require_atomic? false` on `:request_sync`.
  """

  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    extensions: [AshOban],
    notifiers: [Ash.Notifier.PubSub]

  alias Radiator.Podcasts.Podcast.Backoff

  actions do
    update :apply_feed do
      require_atomic? false

      argument :feed, :struct do
        constraints instance_of: Radiator.Feeds.Feed
        allow_nil? true
      end

      change Radiator.Podcasts.Podcast.Changes.ApplyFeed
    end

    update :request_sync do
      accept []
      require_atomic? false

      # Without a url the worker would find nothing under the trigger's `where`
      # and the podcast would sit on `:pending` for good.
      validate present(:feed_url)

      change set_attribute(:sync_status, :pending)

      # A requested sync must not be answered with 304.
      change set_attribute(:http_etag, nil)
      change set_attribute(:http_last_modified, nil)

      change Radiator.Podcasts.Podcast.Changes.CancelWaitingSyncJobs
      change run_oban_trigger(:sync)
    end

    update :mark_sync_failed do
      require_atomic? false

      argument :error, :term

      change Radiator.Podcasts.Podcast.Changes.RecordSyncError
    end

    update :sync do
      require_atomic? false

      argument :feed, :struct do
        constraints instance_of: Radiator.Feeds.Feed
        allow_nil? true
      end

      # A failure that retrying cannot fix; see `FetchFeed`.
      argument :error, :term, allow_nil?: true

      change Radiator.Podcasts.Podcast.Changes.FetchFeed
      change Radiator.Podcasts.Podcast.Changes.ApplyFeed
    end
  end

  oban do
    triggers do
      # The immediate sync comes from `run_oban_trigger`; the cron picks up
      # scheduled podcasts that have come due. After a sync the record no
      # longer matches `where`, so it is not selected again.
      trigger :sync do
        action :sync

        where expr(
                not is_nil(feed_url) and
                  (sync_status == :pending or
                     (sync_strategy == :scheduled and
                        (is_nil(last_checked_at) or last_checked_at < ago(1, :hour))))
              )

        scheduler_cron "*/5 * * * *"
        queue :feeds
        worker_opts unique: [period: :infinity, states: :incomplete, keys: [:primary_key]]
        max_attempts 3
        backoff &Backoff.for_job/1
        on_error :mark_sync_failed
        worker_module_name Radiator.Podcasts.Workers.SyncFeed
        scheduler_module_name Radiator.Podcasts.Schedulers.SyncFeed
      end
    end
  end

  pub_sub do
    module RadiatorWeb.Endpoint
    prefix "podcast"
    # A LiveView then receives a plain `%Phoenix.Socket.Broadcast{}`.
    broadcast_type :phoenix_broadcast

    publish :sync, ["updated", :id]
    publish :apply_feed, ["updated", :id]
    publish :mark_sync_failed, ["updated", :id]
    publish :request_sync, ["updated", :id]
  end

  attributes do
    attribute :sync_strategy, Radiator.Podcasts.SyncStrategy,
      allow_nil?: false,
      default: :manual,
      public?: true

    attribute :sync_status, Radiator.Podcasts.SyncStatus,
      allow_nil?: false,
      default: :idle,
      public?: true

    attribute :last_checked_at, :utc_datetime_usec, public?: true
    attribute :last_imported_at, :utc_datetime_usec, public?: true
    attribute :last_sync_error, :string, public?: true
    attribute :http_etag, :string
    attribute :http_last_modified, :string
  end
end
