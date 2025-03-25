defmodule Radiator.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Radiator.Repo

  alias Radiator.Accounts.{
    User,
    UserNotifier,
    UserToken,
    WebService
  }

  ## Database getters

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Returns a list of users search by using a partial email address

  ## Examples

      iex> search_users("foo@exampl")
      [%User{email: "foo@example.com"}]

      iex> search_users("unknown@example.com")
      []

  """
  def search_users(search_term, limit \\ 10) do
    User
    |> where([u], ilike(u.email, ^"%#{search_term}%"))
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
    Get the user's Raindrop tokens if they exist.

  ## Examples

      iex> get_raindrop_tokens(23)
      %WebService{}

      iex> get_raindrop_tokens(42)
      nil

  """
  def get_raindrop_tokens(user_id) do
    service_name = WebService.raindrop_service_name()

    WebService
    |> where([w], w.user_id == ^user_id)
    |> where([w], w.service_name == ^service_name)
    |> Repo.one()
  end

  @doc """
  Sets a users optional Raindrop tokens and expiration time.
  Given a user id, access token, refresh token, and expiration time,

  ## Examples

      iex> update_raindrop_tokens(23, "11r4", "11vb", ~U[2024-11-02 11:54:31Z])
      {:ok, %User{}}

      iex> update_raindrop_tokens(42, "11r4", "11vb", ~U[2024-11-02 11:54:31Z])
      {:error, %Ecto.Changeset{}}

  """
  def update_raindrop_tokens(
        user_id,
        raindrop_access_token,
        raindrop_refresh_token,
        raindrop_expires_at
      ) do
    %WebService{}
    |> WebService.changeset(%{
      service_name: WebService.raindrop_service_name(),
      user_id: user_id,
      data: %{
        access_token: raindrop_access_token,
        refresh_token: raindrop_refresh_token,
        expires_at: raindrop_expires_at
      }
    })
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :created_at]},
      conflict_target: [:user_id, :service_name],
      set: [updated_at: DateTime.utc_now()]
    )
  end

  @doc """
     Radiator.Accounts.connect_show_with_raindrop(1, 23, 42)
  """
  def connect_show_with_raindrop(user_id, show_id, collection_id) do
    case get_raindrop_tokens(user_id) do
      nil ->
        {:error, "No Raindrop tokens found"}

      %{data: data} = service ->
        data =
          Map.update!(data, :collection_mappings, fn mappings ->
            Map.put(mappings, show_id_to_collection_id(show_id), collection_id)
          end)
          |> Map.from_struct()

        service
        |> WebService.changeset(%{data: data})
        |> Repo.update()
    end
  end

  defp show_id_to_collection_id(show_id) when is_integer(show_id), do: Integer.to_string(show_id)
  defp show_id_to_collection_id(show_id), do: show_id

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## API

  @doc """
  Generates an api token.
  """
  def generate_user_api_token(user) do
    existing_token = get_api_token_by_user(user)

    if is_nil(existing_token) do
      {token, user_token} = UserToken.build_api_token(user)
      Repo.insert!(user_token)
      token
    else
      existing_token
    end
  end

  @doc """
  Gets the api token for the given user.
  """
  def get_api_token_by_user(user) do
    with query <- UserToken.by_user_and_contexts_query(user, ["api"]),
         %UserToken{token: token} <- Repo.one(query) do
      token
    else
      _ -> nil
    end
  end

  @doc """
  Refresh api token.
  """
  def refresh_user_api_token(user) do
    Repo.delete_all(UserToken.by_user_and_contexts_query(user, ["api"]))
    generate_user_api_token(user)
  end

  @doc """
  Gets the user with the given api token.
  """
  def get_user_by_api_token(token) do
    {:ok, query} = UserToken.verify_api_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the api token.
  """
  def delete_user_api_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "api"))
    :ok
  end

  @doc """
  Creates a web service associated with the given user.
  """
  def create_web_service(user_id, service_name, attributes) do
    attrs = %{service_name: service_name, user_id: user_id, data: attributes}

    %WebService{}
    |> WebService.changeset(attrs)
    |> Repo.insert()
  end
end
