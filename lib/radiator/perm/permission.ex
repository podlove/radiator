defmodule Radiator.Perm.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Auth
  alias Radiator.Perm.Ecto.PermissionType

  @primary_key false
  schema "abstract table: permission" do
    belongs_to :user, Auth.User, primary_key: true
    field :subject_id, :integer, primary_key: true
    field :permission, PermissionType, default: :readonly

    timestamps()
  end

  def changeset(perm, params) when is_map(params) do
    perm
    |> cast(params, [:permission])
    |> validate_required([:permission])
    |> foreign_key_constraint(:user_id)
  end
end
