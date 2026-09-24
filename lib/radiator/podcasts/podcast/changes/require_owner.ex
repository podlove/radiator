defmodule Radiator.Podcasts.Podcast.Changes.RequireOwner do
  @moduledoc """
  Fails the update when it would leave the podcast without an owner.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Ash.Error.Changes.InvalidArgument
  alias Radiator.Podcasts.PodcastUserRole

  @impl true
  def change(changeset, _opts, _context) do
    if Ash.Changeset.get_argument(changeset, :memberships) do
      Ash.Changeset.after_action(changeset, &check_owner/2)
    else
      changeset
    end
  end

  defp check_owner(_changeset, podcast) do
    PodcastUserRole
    |> Ash.Query.filter(podcast_id == ^podcast.id and role == :owner)
    |> Ash.exists?(authorize?: false)
    |> case do
      true ->
        {:ok, podcast}

      false ->
        {:error,
         InvalidArgument.exception(
           field: :memberships,
           message: "at least one owner must remain"
         )}
    end
  end
end
