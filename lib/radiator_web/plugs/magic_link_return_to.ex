defmodule RadiatorWeb.Plugs.MagicLinkReturnTo do
  @moduledoc """
  Remembers where a magic link should lead after signing in.

  A link like `/magic_link/<token>?return_to=/admin/podcasts/<id>/edit` stores
  the path in the session, where `RadiatorWeb.AuthController.success/4` picks
  it up. Only local paths are taken, so a link cannot send anybody off-site.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{path_info: ["magic_link" | _rest]} = conn, _opts) do
    conn = fetch_query_params(conn)

    case conn.query_params["return_to"] do
      "/" <> rest = path when rest == "" or binary_part(rest, 0, 1) not in ["/", "\\"] ->
        put_session(conn, :return_to, path)

      _missing_or_foreign ->
        conn
    end
  end

  def call(conn, _opts), do: conn
end
