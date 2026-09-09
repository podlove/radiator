defmodule Radiator.Podcasts.Podcast.Changes.CancelWaitingSyncJobs do
  @moduledoc """
  Cancels sync jobs that are waiting for their turn, so a requested sync runs
  now.

  After a transient failure Oban parks the job as `retryable` for up to an
  hour, and per-record uniqueness would refuse a second one until then.
  Cancelling the waiting job lets `run_oban_trigger` insert a fresh one. Jobs
  that are `available` or `executing` are left alone; they are about to deliver
  anyway.
  """

  use Ash.Resource.Change

  import Ecto.Query

  @worker "Radiator.Podcasts.Workers.SyncFeed"
  @waiting ~w(scheduled retryable)

  @impl true
  def change(changeset, _opts, _context) do
    # Inside the transaction and ahead of `run_oban_trigger`'s `after_action`.
    Ash.Changeset.before_action(changeset, &cancel_waiting(&1))
  end

  defp cancel_waiting(changeset) do
    id = changeset.data.id

    Oban.Job
    |> where([j], j.worker == @worker and j.state in @waiting)
    |> where([j], fragment("?->'primary_key'->>'id' = ?", j.args, ^id))
    |> Oban.cancel_all_jobs()

    changeset
  end
end
