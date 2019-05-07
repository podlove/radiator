defmodule Radiator.Auth.User do
  use Ecto.Schema
  use Arc.Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Radiator.Auth.User

  schema "auth_users" do
    field :name, :string
    field :email, :string
    field :display_name, :string
    field :avatar, Radiator.Media.UserAvatar.Type
    field :password_hash, :binary
    field :password, :string, virtual: true
    field :status, Radiator.Auth.Ecto.UserStatusType, default: :unverified
    # unverified, active, suspended

    timestamps()
  end

  @doc """
  this is the upper bound of reserved `user_id`s. All regular users need to have an id above this.
  """
  def max_reserved_user_id, do: 10

  def reserved_user(:public) do
    %User{
      id: 1,
      name: "public",
      display_name: "Public",
      email: "public@public.local",
      password_hash: "thoushaltnotpass"
    }
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :display_name, :password, :password_hash, :status])
    |> cast_attachments(attrs, [:avatar])
    |> unique_constraint(:name, name: :auth_users__lower_name_index)
    |> unique_constraint(:email, name: :auth_users__lower_email_index)
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

  @request_email_salt "34ercft gpaojrt[we"
  @email_verification_salt "q3480haspodfinp0284;a"

  def email_verification_request_token(%User{} = user) do
    Phoenix.Token.sign(RadiatorWeb.Endpoint, @request_email_salt, user.name)
  end

  def validate_email_verification_request_token(token) do
    Phoenix.Token.verify(RadiatorWeb.Endpoint, @request_email_salt, token, max_age: 60 * 5)
  end

  @spec email_verification_token(Radiator.Auth.User.t()) :: any()
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

  def by_email_query(email) do
    email_downcase = String.downcase(email)

    from u in User,
      where: fragment("lower(?)", u.email) == ^email_downcase
  end

  def by_name_query(name) do
    name_downcase = String.downcase(name)

    from u in User,
      where: fragment("lower(?)", u.name) == ^name_downcase
  end
end
