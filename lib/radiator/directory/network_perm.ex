defmodule Radiator.Directory.NetworkPermission do
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Auth
  alias Radiator.Directory.Network
  alias Radiator.Perm.Ecto.PermissionType

  @primary_key false
  schema "networks_perm" do
    belongs_to :user, Auth.User, primary_key: true
    belongs_to :network, Network, primary_key: true
    field :permission, PermissionType, default: :readonly

    timestamps()
  end

  def changeset(perm, params) when is_map(params) do
    perm
    |> cast(params, [:permission])
    |> validate_required([:permission])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:network_id)
  end
end
