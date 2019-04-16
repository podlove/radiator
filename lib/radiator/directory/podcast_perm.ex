defmodule Radiator.Directory.PodcastPermission do
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Auth
  alias Radiator.Directory.Podcast
  alias Radiator.Perm.Ecto.PermissionType

  schema "podcasts_perm" do
    belongs_to :user, Auth.User
    belongs_to :podcast, Podcast
    field :permission, PermissionType, default: :readonly

    timestamps()
  end

  def changeset(perm, params) when is_map(params) do
    perm
    |> cast(params, [:permission])
    |> validate_required([:permission])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:podcast_id)
  end
end
