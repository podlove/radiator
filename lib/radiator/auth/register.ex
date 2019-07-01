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

  def find_users(query_string \\ "") do
    query =
      from u in User,
        where: ilike(u.name, ^"#{query_string}%"),
        or_where: ilike(u.display_name, ^"#{query_string}%"),
        preload: [:person]

    Repo.all(query)
  end

  # TODO: we want to always have a person associated with a user but can we do it without coupling the logic here?
  def create_user(attrs \\ %{}) do
    {person_attrs, user_attrs} = Map.split(attrs, [:nick, :avatar])

    %User{}
    |> User.changeset(user_attrs)
    |> Ecto.Changeset.put_assoc(:person, person_attrs)
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
