defmodule Radiator.Podcasts.Podcast.Changes.ResetHttpCache do
  @moduledoc """
  Clears the conditional-request validators when the feed url changes, so the
  old feed's `If-None-Match` is never sent to the new server.
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    if Ash.Changeset.changing_attribute?(changeset, :feed_url) do
      changeset
      |> Ash.Changeset.force_change_attribute(:http_etag, nil)
      |> Ash.Changeset.force_change_attribute(:http_last_modified, nil)
    else
      changeset
    end
  end

  @impl true
  def atomic(changeset, opts, context), do: {:ok, change(changeset, opts, context)}
end
