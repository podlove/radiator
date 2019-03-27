defmodule Radiator.Auth.Directory do
  @moduledoc """
  The Account Directory Context
  """

  alias Radiator.Auth.Repo
  alias Radiator.Auth.User

  def get_user(id), do: Repo.get!(User, id)

  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def get_user_by_name(name), do: Repo.get_by(User, name: name)

  def get_user_by_credentials(name_or_email, password) do
    case get_user_by_name(name_or_email) || get_user_by_email(name_or_email) do
      nil ->
        nil

      user ->
        case Argon2.check_pass(user, password) do
          {:ok, _} ->
            user

          _ ->
            nil
        end
    end
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def change_user(%User{} = user), do: User.changeset(user, %{})
end
