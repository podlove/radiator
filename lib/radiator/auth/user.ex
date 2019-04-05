defmodule Radiator.Auth.Ecto.UserStatusType do
  @behaviour Ecto.Type

  @status_values [:unverified, :active, :suspended]

  def allowed_values do
    @status_values
  end

  def type, do: :binary

  def cast(binary) when is_binary(binary), do: cast(String.to_existing_atom(binary))

  def cast(atom) when is_atom(atom) do
    if atom in @status_values do
      {:ok, atom}
    else
      :error
    end
  end

  def load(data) when is_binary(data) do
    {:ok, String.to_existing_atom(data)}
  end

  def dump(atom) when is_atom(atom) do
    {:ok, Atom.to_string(atom)}
  end
end

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
    field :status, Radiator.Auth.Ecto.UserStatusType, default: :unverified
    # unverified, active, suspended

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :display_name, :password, :password_hash, :status])
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
end
