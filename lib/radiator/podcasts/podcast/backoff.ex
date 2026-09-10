defmodule Radiator.Podcasts.Podcast.Backoff do
  @moduledoc """
  How long to wait before retrying a feed sync.

  A server that answers 429 or 503 with a `Retry-After` has told us when to come
  back; ignoring that is how one earns a block. Everything else backs off
  exponentially. The cap keeps an absurd `Retry-After` from parking a job for
  days.
  """

  alias Radiator.Podcasts.FeedSyncError

  @max_seconds 3_600

  @doc "Retry delay in seconds for an Oban job."
  def for_job(%Oban.Job{unsaved_error: %{reason: reason}, attempt: attempt}) do
    case retry_after(reason) do
      seconds when is_integer(seconds) and seconds > 0 -> min(seconds, @max_seconds)
      _other -> exponential(attempt)
    end
  end

  def for_job(%Oban.Job{attempt: attempt}), do: exponential(attempt)

  # What Oban hands back is the Ash error class the action failed with; the
  # `FeedSyncError` carrying the seconds sits somewhere in its `errors`, and
  # the classes nest, hence the recursion.
  defp retry_after(%FeedSyncError{retry_after: seconds}), do: seconds

  defp retry_after(%{errors: errors}) when is_list(errors),
    do: Enum.find_value(errors, &retry_after/1)

  defp retry_after(_reason), do: nil

  defp exponential(attempt) do
    min(trunc(:math.pow(max(attempt, 1), 4)) + 15, @max_seconds)
  end
end
