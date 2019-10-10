defmodule RadiatorWeb.Plug.CustomPublicURLs do
  @behaviour Plug

  import Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn = %Plug.Conn{host: host}, _opts) do
    if instance_host() == host do
      conn
    else
      if host == "ukw.foobar.de" do
        # actually: fetch podcast from db via host
        podcast = Radiator.Directory.get_podcast(2) |> IO.inspect()

        conn
        |> assign(:custom_public_url, true)
        |> assign(:current_podcast, podcast)
      else
        conn
      end
    end
  end

  defp instance_host do
    Application.get_env(:radiator, RadiatorWeb.Endpoint) |> get_in([:url, :host])
  end
end
