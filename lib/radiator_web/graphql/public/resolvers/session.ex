alias Radiator.Auth

defmodule RadiatorWeb.GraphQL.Public.Resolvers.Session do
  def get_authenticated_session(
        _parent,
        %{username_or_email: username_or_email, password: password},
        _resolution
      ) do
    case Auth.Register.get_user_by_credentials(username_or_email, password) do
      nil ->
        {:error, "Invalid credentials"}

      valid_user ->
        new_session_for_valid_user(valid_user)
    end
  end

  def signup(
        _parent,
        %{username: username, email: email, password: password},
        %{context: context}
      ) do
    case Auth.Register.create_user(%{
           name: username,
           email: email,
           password: password
         }) do
      {:ok, user} ->
        with authenticated_user = %Auth.User{} <- context[:authenticated_user],
             :active <- authenticated_user.status do
          # activate user immediatly when created by an already authenticated user
          Auth.Register.activate_user(user)
        else
          _ ->
            # Todo: resolve the depency on the login controller more gracefully for the email activation
            user
            |> Auth.Email.email_verification_email(
              RadiatorWeb.LoginController.email_configuration_url(context.context_conn, user)
            )
            |> Radiator.Mailer.deliver_later()
        end

        new_session_for_valid_user(user)

      {:error, _changeset} ->
        {:error, "Failed to create #{username} <#{email}>"}
    end
  end

  @doc """
  Helper method to be shared
  """
  def new_session_for_valid_user(user) do
    token = Auth.Guardian.api_session_token(user)

    {:ok,
     %{
       username: user.name,
       token: token,
       expires_at: Auth.Guardian.get_expiry_datetime(token)
     }}
  end
end
