defmodule RadiatorWeb.Plug.CustomPublicURLs do
  @behaviour Plug

  import Plug.Conn

  alias Radiator.Directory
  alias Radiator.Directory.Podcast
  alias Radiator.InstanceConfig

  @impl Plug
  def init(opts), do: opts

  # todo: if host is custom but cannot be matched, show error page with explanation
  @impl Plug
  def call(conn = %Plug.Conn{host: host}, _opts) do
    if InstanceConfig.hostname() == host do
      conn
    else
      Directory.get_podcast_by_hostname(host)
      |> case do
        nil ->
          conn

        podcast = %Podcast{} ->
          conn
          |> assign(:current_podcast, podcast)
      end
    end
  end
end
