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

  def changeset(perm, params \\ {}) do
    perm
    |> cast(params, [:user_id, :podcast_id, :permission])
    |> validate_required([:user_id, :podcast_id, :permission])
    |> unique_constraint(:permission, name: :podcasts_perm_user_id_podcast_id_permission_index)
  end
end
