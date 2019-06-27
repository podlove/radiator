defmodule RadiatorWeb.Api.NetworkView do
  use RadiatorWeb, :view

  alias HAL.{Document, Link}

  def render("show.json", assigns) do
    render(__MODULE__, "network.json", assigns)
  end

  def render("network.json", %{conn: conn, network: network}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_network_path(conn, :show, network)
    })
    |> Document.add_properties(%{
      id: network.id,
      title: network.title
    })
  end
end
