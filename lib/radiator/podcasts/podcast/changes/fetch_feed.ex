defmodule Radiator.Podcasts.Podcast.Changes.FetchFeed do
  @moduledoc """
  Fetches and parses the feed, then hands it to `ApplyFeed` as the `:feed`
  argument.

  The work sits in a `before_transaction` hook on purpose: an Ash update action
  runs inside a database transaction, and a network round trip in there would
  hold row locks open for its whole duration.

  Failures come in two kinds. A transient one (timeout, 5xx, truncated body) is
  added as an error, so the action fails and Oban retries it. A permanent one
  (404, wrong content type, not a feed) is handed on as the `:error` argument
  instead: `ApplyFeed` records it, the action succeeds, and the job completes
  without further attempts.
  """

  use Ash.Resource.Change

  alias Radiator.Feeds
  alias Radiator.Feeds.ParseError
  alias Radiator.Podcasts.FeedSyncError

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, &fetch/1)
  end

  # `force_set_argument/3`: inside a hook the changeset already counts as
  # validated and the plain setter would warn on every sync.
  defp fetch(changeset) do
    podcast = changeset.data

    case Feeds.load(podcast.feed_url, request_options(podcast)) do
      {:ok, feed, response} ->
        changeset
        |> Ash.Changeset.force_set_argument(:feed, feed)
        |> store_validators(response)

      {:not_modified, _response} ->
        Ash.Changeset.force_set_argument(changeset, :feed, nil)

      {:error, reason} ->
        handle_error(changeset, reason)
    end
  end

  # Always conditional; `:request_sync` clears these two when a 304 is unwanted.
  defp request_options(podcast) do
    [etag: podcast.http_etag, last_modified: podcast.http_last_modified]
  end

  defp store_validators(changeset, response) do
    changeset
    |> Ash.Changeset.force_change_attribute(:http_etag, response.etag)
    |> Ash.Changeset.force_change_attribute(:http_last_modified, response.last_modified)
  end

  defp handle_error(changeset, reason) do
    if permanent?(reason) do
      Ash.Changeset.force_set_argument(changeset, :error, reason)
    else
      Ash.Changeset.add_error(changeset, FeedSyncError.from_reason(reason))
    end
  end

  defp permanent?({:http_status, status}) when status in [400, 401, 403, 404, 410], do: true
  defp permanent?({:unexpected_content_type, _type}), do: true
  # `:malformed_xml` is what a truncated transfer looks like, so it is retried.
  defp permanent?(%ParseError{reason: :not_a_feed}), do: true
  defp permanent?(_reason), do: false
end
