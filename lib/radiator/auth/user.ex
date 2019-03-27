defmodule Radiator.Auth.User do
  alias Radiator.Auth.User

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "auth_users" do
    field :name, :string
    field :email, :string
    field :display_name, :string
    field :password_hash, :binary
    field :password, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :display_name, :password, :password_hash])
    |> unique_constraint(:name)
    |> unique_constraint(:email)
    |> validate_format(:name, ~r/^[^\s ]+$/)
    |> validate_format(:email, ~r/^\S+@\S+$/)
    |> validate_length(:name, min: 2, max: 99)
    |> validate_required([:email, :name])
    |> encrypt_password
    |> validate_required([:password_hash])
  end

  defp encrypt_password(changeset) do
    plain_password = get_change(changeset, :password)

    if plain_password do
      add_password_hash_map = Argon2.add_hash(plain_password)
      change(changeset, add_password_hash_map)
    else
      changeset
    end
  end

  def check_password(%User{} = user, password) do
    Argon2.check_pass(user, password)
  end
end
