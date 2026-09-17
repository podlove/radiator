defmodule RadiatorWeb.HomeLive.Index do
  use RadiatorWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias Radiator.Podcasts

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      RadiatorWeb.Endpoint.subscribe("podcast:created")
      RadiatorWeb.Endpoint.subscribe("podcast:updated")
      RadiatorWeb.Endpoint.subscribe("podcast:destroyed")
    end

    load = [:episodes]
    podcasts = Podcasts.public_read_podcasts!(load: load, stream?: true)

    socket
    |> assign(:page_title, "Podcasts")
    |> stream(:podcasts, podcasts)
    |> ok()
  end

  @impl true
  def handle_info(%Broadcast{topic: "podcast:created", event: "create", payload: payload}, socket) do
    %{payload: %{data: podcast}} = payload

    socket
    |> stream_insert(:podcasts, podcast, at: 0)
    |> noreply()
  end

  def handle_info(%Broadcast{topic: "podcast:updated", event: "update", payload: payload}, socket) do
    %{payload: %{data: podcast}} = payload

    socket
    |> stream_insert(:podcasts, podcast, at: -1)
    |> noreply()
  end

  def handle_info(%Broadcast{topic: "podcast:updated", event: "sync", payload: _payload}, socket) do
    socket
    |> noreply()
  end

  def handle_info(
        %Broadcast{topic: "podcast:destroyed", event: "destroy", payload: payload},
        socket
      ) do
    %{payload: %{data: podcast}} = payload

    socket
    |> stream_delete(:podcasts, podcast)
    |> noreply()
  end
end
