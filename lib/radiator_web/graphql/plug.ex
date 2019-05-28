defmodule RadiatorWeb.GraphQL.Plug do
  alias RadiatorWeb.GraphQL

  @guest_schema Absinthe.Plug.init(schema: GraphQL.Public.Schema)
  @admin_schema Absinthe.Plug.init(schema: GraphQL.Admin.Schema)

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.private[:absinthe].context do
      %{authenticated_user: _user} -> Absinthe.Plug.call(conn, @admin_schema)
      _ -> Absinthe.Plug.call(conn, @guest_schema)
    end
  end
end
