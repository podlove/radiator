defmodule Radiator.Auth.Register do
  @moduledoc """
  The Authentication Register Context, giving access to  `Auth.Users` and related data
  """

  alias Radiator.Repo
  alias Radiator.Auth.User

  def get_user(id), do: Repo.get!(User, id)

  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def get_user_by_name(name), do: Repo.get_by(User, name: name)

  def get_user_by_credentials(name_or_email, password) do
    max_id = User.max_reserved_user_id()

    case get_user_by_name(name_or_email) || get_user_by_email(name_or_email) do
      user = %User{id: user_id} when user_id > max_id ->
        case Argon2.check_pass(user, password) do
          {:ok, _} ->
            user

          _ ->
            nil
        end

      _ ->
        nil
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

  def activate_user(%User{} = user) do
    get_user_by_email(user.email)
    |> update_user(%{status: :active})
  end

  def change_user(%User{} = user, attrs \\ %{}), do: User.changeset(user, attrs)
end
