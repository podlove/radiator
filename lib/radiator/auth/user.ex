defmodule Radiator.Auth.User do
  alias Radiator.Auth.User

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "users" do
    field :name, :string
    field :email, :string
    field :pass, :string
    field :plain_password, :string, virtual: true
    field :display_name, :string

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :plain_password, :pass, :display_name])
    |> unique_constraint(:name)
    |> unique_constraint(:email)
    |> validate_format(:name, ~r/^[^\s ]+$/)
    |> validate_format(:email, ~r/^\S+@\S+$/)
    |> validate_length(:name, min: 2, max: 99)
    |> validate_required([:email, :name])
    |> encrypt_password
    |> validate_required([:pass])
  end

  defp encrypt_password(changeset) do
    plain_password = get_change(changeset, :plain_password)

    if plain_password do
      encrypted_password = plain_password
      put_change(changeset, :pass, encrypted_password)
    else
      changeset
    end
  end
end
