defmodule Radiator.Podcasts.FeedSyncError do
  @moduledoc """
  Why a feed sync failed, in a form that survives the trip out to Oban.

  A bare `Ash.Changeset.add_error(changeset, message: "...")` would carry the
  text but nothing else. Oban only ever sees the wrapping `Ash.Error.Invalid`,
  so anything the retry logic needs — here the `Retry-After` a server asked
  for — has to travel as a field on an error struct rather than as a tuple
  that is discarded on the way.
  """

  use Splode.Error, fields: [:reason, :retry_after], class: :invalid

  @doc """
  Wraps a feed client failure.

  `retry_after` is filled from the 429 and 503 responses that name one, and is
  read back out by `Radiator.Podcasts.Podcast.Backoff`.
  """
  def from_reason(reason) do
    exception(reason: reason, retry_after: retry_after(reason))
  end

  defp retry_after({:http_status, status, seconds})
       when status in [429, 503] and is_integer(seconds) and seconds > 0,
       do: seconds

  defp retry_after(_reason), do: nil

  @impl true
  def message(%{reason: reason}), do: describe(reason)

  @doc """
  A single readable line for whatever went wrong.

  Ash wraps errors in a class whose own `Exception.message/1` renders bread
  crumbs and a stacktrace — fine in a log, useless in the UI. This digs out the
  errors that actually say something.
  """
  # `describe/1` rather than `message/1`: Splode overrides the latter to prefix
  # bread crumbs, which is the very noise this function exists to strip.
  def summarize(%__MODULE__{reason: reason}), do: describe(reason)

  def summarize(%{errors: [_ | _] = errors}) do
    errors
    |> Enum.map(&summarize/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.join("; ")
  end

  def summarize(reason), do: describe(reason)

  defp describe(reason) when is_binary(reason), do: reason
  defp describe({:http_status, status}), do: "HTTP #{status}"
  defp describe({:http_status, status, nil}), do: "HTTP #{status}"

  defp describe({:http_status, status, seconds}),
    do: "HTTP #{status}, retry after #{seconds} s"

  defp describe({:unexpected_content_type, type}), do: "Unexpected content type: #{type}"
  defp describe(:feed_too_large), do: "Feed exceeds the size limit"

  defp describe(reason) when is_exception(reason), do: Exception.message(reason)
  defp describe(reason), do: inspect(reason)
end
