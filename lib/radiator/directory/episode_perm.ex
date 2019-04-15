defmodule Radiator.Directory.EpisodePermission do
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Auth
  alias Radiator.Directory.Episode
  alias Radiator.Perm.Ecto.PermissionType

  schema "episodes_perm" do
    belongs_to :user, Auth.User
    belongs_to :episode, Episode
    field :permission, PermissionType, default: :readonly

    timestamps()
  end

  def changeset(perm, params \\ %{}) do
    perm
    |> cast(params, [:user_id, :episode_id, :permission])
    |> validate_required([:user_id, :episode_id, :permission])
    |> unique_constraint(:permission, name: :episodes_perm_user_id_episode_id_index)
  end
end
