defmodule Radiator.Auth.Register do
  @moduledoc """
  The Authentication Register Context, giving access to  `Auth.Users` and related data
  """

  import Ecto.Query

  alias Radiator.Repo
  alias Radiator.Auth.User

  def get_user(id),
    do: Repo.get!(User, id)

  def get_user_by_email(email),
    do:
      email
      |> User.by_email_query()
      |> Repo.one()

  def get_user_by_name(name),
    do:
      name
      |> User.by_name_query()
      |> Repo.one()

  def user_by_name_or_email(name_or_email) do
    name_or_email
    |> User.by_name_or_email_query()
    |> Repo.one()
    |> case do
      user = %User{} -> {:ok, user}
      nil -> {:error, :not_found}
    end
  end

  def get_user_by_credentials(name_or_email, password) do
    max_reserved_id = User.max_reserved_user_id()

    with {:ok, user = %User{id: user_id}} when user_id > max_reserved_id <-
           user_by_name_or_email(name_or_email),
         {:ok, _} <- Argon2.check_pass(user, password) do
      user
    else
      _ -> nil
    end
  end

  defp users_query("") do
    from u in User, order_by: u.display_name, preload: [:person]
  end

  defp users_query(query_string) do
    from u in users_query(""),
      where: ilike(u.name, ^"#{query_string}%"),
      or_where: ilike(u.display_name, ^"#{query_string}%")
  end

  def find_users(query_string \\ "") do
    users_query(query_string)
    |> Repo.all()
  end

  # TODO: we want to always have a profile associated with a user but can we do it without coupling the logic here?
  def create_user(attrs \\ %{}) do
    {profile_attrs, user_attrs} =
      Map.split(attrs, [:display_name, :image, "display_name", "image"])

    %User{}
    |> User.changeset(user_attrs)
    |> Ecto.Changeset.put_assoc(:profile, profile_attrs)
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

  def change_password(%User{} = user, attrs) do
    user
    |> User.change_password_changeset(attrs)
    |> Repo.update()
  end
end
