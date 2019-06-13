defmodule Radiator.Auth.Guardian do
  @otp_app Mix.Project.config()[:app]
  use Guardian, otp_app: @otp_app

  alias Radiator.Auth

  @doc """
  Generates and returns a Bearer token for api usage.
  """
  def api_session_token(%Auth.User{} = user) do
    {:ok, token, _claims} =
      encode_and_sign(user, %{}, ttl: {45, :minutes}, token_type: :api_session)

    token
  end

  @doc """
  Returns the expiry time of a token as `DateTime`. Returns value in the past if invalid or expired.
  """
  def get_expiry_datetime(token) do
    {:ok, datetime} =
      case Guardian.decode_and_verify(__MODULE__, token) do
        {:ok, %{"exp" => expiry_timestamp}} ->
          DateTime.from_unix(expiry_timestamp)

        # treat as expired
        _ ->
          DateTime.from_unix(0)
      end

    datetime
  end

  # Callbacks

  @impl Guardian
  def subject_for_token(%Auth.User{} = resource, _claims) do
    # You can use any value for the subject of your token but
    # it should be useful in retrieving the resource later, see
    # how it being used on `resource_from_claims/1` function.
    # A unique `id` is a good subject, a non-unique email address
    # is a poor subject.
    sub = to_string(resource.name)
    {:ok, sub}
  end

  @impl Guardian
  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  @impl Guardian
  def resource_from_claims(claims) when is_map(claims) do
    # Here we'll look up our resource from the claims, the subject can be
    # found in the `"sub"` key. In `above subject_for_token/2` we returned
    # the resource id so here we'll rely on that to look it up.
    username = claims["sub"]

    case Radiator.Auth.Register.get_user_by_name(username) do
      nil ->
        {:error, :resource_not_found}

      resource ->
        {:ok, resource}
    end
  end

  @impl Guardian
  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end

  @impl Guardian
  # Remove some of the optional default claims for now
  # as long as they don't provide additional benefit/safety for us

  # From the spec at https://tools.ietf.org/html/rfc7519
  # * 'jti' JWT ID - a unique identifier for a token
  # * 'aud' audience - intended audience
  # * 'ndf' not before - token is invalid before that time
  # * 'iat' issued at - time the token was issued

  def build_claims(claims, _subject, _options) do
    claims =
      claims
      |> Enum.reject(fn
        {key, _value} when key in ["jti", "aud", "nbf", "iat"] -> true
        _ -> false
      end)
      |> Map.new()

    {:ok, claims}
  end
end
