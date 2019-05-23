defmodule RadiatorWeb.GraphQL.Admin.Schema.Middleware.RequireAuthentication do
  @behaviour Absinthe.Middleware

  def call(resolution, _) do
    case resolution.context do
      %{authenticated_user: _} ->
        resolution

      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, "Authentication: Needs authenticated user."})
    end
  end
end
