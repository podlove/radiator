defmodule Radiator.Auth.Guardian do
  @otp_app Mix.Project.config()[:app]
  use Guardian, otp_app: @otp_app

  alias Radiator.Auth

  @doc """
  Generates and returns a Bearer token for api usage.
  """
  def api_session_token(%Auth.User{} = user) do
    {:ok, token, _tokenparams} = encode_and_sign(user, %{}, ttl: {45, :minutes})

    token
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
    id = claims["sub"]

    case Radiator.Auth.Register.get_user_by_name(id) do
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
end
