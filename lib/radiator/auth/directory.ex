defmodule Radiator.Auth.Directory do
  @moduledoc """
  The Account Directory Context
  """

  alias Radiator.Auth.Repo
  alias Radiator.Auth.User

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email!(email), do: Repo.get_by(User, email: email)

  def get_user_by_user_name!(user_name), do: Repo.get_by(User, user_name: user_name)

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
