defmodule RadiatorWeb.Api.NetworkView do
  use RadiatorWeb, :view

  alias HAL.{Document, Link}

  alias Radiator.Directory.Network

  def render("show.json", assigns) do
    render(__MODULE__, "network.json", assigns)
  end

  def render("network.json", %{conn: conn, network: network = %Network{}}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_network_path(conn, :show, network)
    })
    |> Document.add_properties(%{
      id: network.id,
      title: network.title,
      image: Network.image_url(network)
    })
  end
end
