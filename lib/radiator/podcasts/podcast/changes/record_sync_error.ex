defmodule Radiator.Podcasts.Podcast.Changes.RecordSyncError do
  @moduledoc """
  Writes the failed state and a one-line summary of the error.

  Used by `:mark_sync_failed` after the last attempt and by `ApplyFeed` for
  failures not worth retrying.
  """

  use Ash.Resource.Change

  alias Radiator.Podcasts.FeedSyncError

  @limit 1_000

  @impl true
  def change(changeset, _opts, _context) do
    error = Ash.Changeset.get_argument(changeset, :error)

    record(changeset, error, DateTime.utc_now())
  end

  @doc "Writes the failed state for `error`, checked at `now`."
  def record(changeset, error, now) do
    changeset
    |> Ash.Changeset.force_change_attribute(:sync_status, :failed)
    |> Ash.Changeset.force_change_attribute(:last_sync_error, describe(error))
    |> Ash.Changeset.force_change_attribute(:last_checked_at, now)
  end

  defp describe(nil), do: "Unknown error"
  defp describe(error), do: error |> FeedSyncError.summarize() |> String.slice(0, @limit)
end
