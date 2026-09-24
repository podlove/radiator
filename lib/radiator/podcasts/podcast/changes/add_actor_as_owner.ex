defmodule Radiator.Podcasts.Podcast.Changes.AddActorAsOwner do
  @moduledoc """
  Makes the user who creates a podcast its owner.

  Runs after the memberships passed along with the create, so it upserts: a
  creator who listed their own address still ends up as owner.
  """

  use Ash.Resource.Change

  alias Radiator.Podcasts.PodcastUserRole

  @impl true
  def change(changeset, _opts, %{actor: %{id: user_id}}) do
    Ash.Changeset.after_action(changeset, fn _changeset, podcast ->
      add_owner(podcast, user_id)
    end)
  end

  def change(changeset, _opts, _context) do
    Ash.Changeset.add_error(changeset, "a podcast needs an actor to become its owner")
  end

  defp add_owner(podcast, user_id) do
    PodcastUserRole
    |> Ash.Changeset.for_create(
      :create,
      %{podcast_id: podcast.id, user_id: user_id, role: :owner},
      authorize?: false,
      upsert?: true,
      upsert_identity: :unique_user_per_podcast,
      upsert_fields: [:role]
    )
    |> Ash.create()
    |> case do
      {:ok, _membership} -> {:ok, podcast}
      {:error, error} -> {:error, error}
    end
  end
end
