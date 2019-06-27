defmodule RadiatorWeb.GraphQL.Admin.Schema.Middleware.RequireAuthentication do
  @behaviour Absinthe.Middleware

  def call(resolution, _) do
    case resolution.context do
      %{current_user: user} ->
        case user.status do
          :active ->
            resolution

          _ ->
            resolution
            |> Absinthe.Resolution.put_result({:error, "Authentication: Needs activated user."})
        end

      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, "Authentication: Needs authenticated user."})
    end
  end
end
