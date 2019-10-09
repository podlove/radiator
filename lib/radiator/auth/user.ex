defmodule Radiator.Auth.User do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Radiator.Auth.User

  schema "auth_users" do
    field :name, :string
    field :email, :string
    field :password_hash, :binary
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :status, Radiator.Auth.Ecto.UserStatusType, default: :unverified
    # unverified, active, suspended

    has_many :people, Radiator.Contribution.Person
    has_one :profile, Radiator.Directory.UserProfile

    timestamps()
  end

  @doc """
  this is the upper bound of reserved `user_id`s. All regular users need to have an id above this. This was/is intended for special users, of which there currently is none.
  """
  def max_reserved_user_id, do: 10

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :password_hash, :status])
    |> unique_constraint(:name, name: :auth_users__lower_name_index)
    |> unique_constraint(:email, name: :auth_users__lower_email_index)
    |> validate_format(:name, ~r/^[^\s ]+$/)
    |> validate_format(:email, ~r/^\S+@\S+$/)
    |> validate_length(:name, min: 2, max: 99)
    |> validate_length(:password, min: 2)
    |> validate_required([:email, :name])
    |> encrypt_password
    |> validate_required([:password_hash])
  end

  def change_password_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 2)
    |> password_and_confirmation_matches
    |> encrypt_password
    |> validate_required([:password_hash])
  end

  ## Changeset Pipeline

  defp password_and_confirmation_matches(changeset) do
    password = get_change(changeset, :password)
    password_confirmation = get_change(changeset, :password_confirmation)

    if password == password_confirmation do
      changeset
    else
      changeset
      |> add_error(:password_confirmation, "does not match password")
    end
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

  ## Public API

  def check_password(%User{} = user, password) do
    Argon2.check_pass(user, password)
  end

  @request_email_salt "34ercft gpaojrt[we"
  @email_verification_salt "q3480haspodfinp0284;a"
  @request_reset_password_email_salt "0987unb23nfi"
  @passwort_reset_salt "oiebibasdfiubp9u3//."

  def email_verification_request_token(%User{} = user) do
    Phoenix.Token.sign(RadiatorWeb.Endpoint, @request_email_salt, user.name)
  end

  def validate_email_verification_request_token(token) do
    Phoenix.Token.verify(RadiatorWeb.Endpoint, @request_email_salt, token, max_age: 60 * 5)
  end

  def email_reset_password_request_token(%User{} = user) do
    Phoenix.Token.sign(RadiatorWeb.Endpoint, @request_reset_password_email_salt, user.name)
  end

  def validate_email_reset_password_request_token(token) do
    Phoenix.Token.verify(RadiatorWeb.Endpoint, @request_reset_password_email_salt, token,
      max_age: 60 * 5
    )
  end

  def email_verification_token(%User{} = user) do
    Phoenix.Token.sign(
      RadiatorWeb.Endpoint,
      @email_verification_salt,
      "#{user.name} #{user.email}"
    )
  end

  def validate_email_verification_token(token) do
    case Phoenix.Token.verify(RadiatorWeb.Endpoint, @email_verification_salt, token,
           max_age: 60 * 60 * 48
         ) do
      {:ok, binary} ->
        [name, email] = :binary.split(binary, " ")

        case Radiator.Auth.Register.get_user_by_email(email) do
          %User{name: ^name} = user -> {:ok, user}
          _ -> {:error, :invalid}
        end

      result ->
        result
    end
  end

  def reset_password_token(%User{} = user) do
    Phoenix.Token.sign(
      RadiatorWeb.Endpoint,
      @passwort_reset_salt,
      "#{user.name} #{user.email}"
    )
  end

  def validate_reset_password_token(token) do
    case Phoenix.Token.verify(RadiatorWeb.Endpoint, @passwort_reset_salt, token, max_age: 60 * 60) do
      {:ok, binary} ->
        [name, email] = :binary.split(binary, " ")

        case Radiator.Auth.Register.get_user_by_email(email) do
          %User{name: ^name} = user -> {:ok, user}
          _ -> {:error, :invalid}
        end

      result ->
        result
    end
  end

  def by_email_query(email) do
    email_downcase = String.downcase(email)

    from u in User,
      where: fragment("lower(?)", u.email) == ^email_downcase,
      preload: [:profile]
  end

  def by_name_query(name) do
    name_downcase = String.downcase(name)

    from u in User,
      where: fragment("lower(?)", u.name) == ^name_downcase,
      preload: [:profile]
  end

  def by_name_or_email_query(name_or_email) do
    name_or_email_downcase = String.downcase(name_or_email)

    from u in User,
      where: fragment("lower(?)", u.name) == ^name_or_email_downcase,
      or_where: fragment("lower(?)", u.email) == ^name_or_email_downcase,
      preload: [:profile]
  end
end
