defmodule RadiatorWeb.Plug.BlockKnownPaths do
  @behaviour Plug

  import Plug.Conn

  # Bail early on known paths so we don't do unneccesary processing

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    basename = Path.basename(conn.request_path)

    [
      "contentWindow.map",
      # from our own webplayer
      ".php"
      # all sorts of scrapers trying to use exploits, e.g. wp-login.php et al
    ]
    |> Enum.reduce(conn, fn
      path_end, conn ->
        if String.ends_with?(basename, path_end) do
          conn
          |> put_status(:not_found)
          |> Phoenix.Controller.put_view(RadiatorWeb.ErrorView)
          |> Phoenix.Controller.render("404.html")
          |> halt()
        else
          conn
        end
    end)
  end
end
