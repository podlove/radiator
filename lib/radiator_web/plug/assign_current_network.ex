defmodule RadiatorWeb.Plug.AssignCurrentNetwork do
  @behaviour Plug

  import Plug.Conn
  import Radiator.Directory, only: [get_network: 1]

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case Map.get(conn.path_params, "network_id") do
      nil ->
        conn

      network_id when is_binary(network_id) ->
        assign(
          conn,
          :current_network,
          network_id |> String.to_integer() |> get_network()
        )
    end
  end
end
