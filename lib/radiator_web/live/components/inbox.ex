defmodule RadiatorWeb.Components.Inbox do
  @moduledoc false
  use RadiatorWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> reply(:ok)
  end

  @impl true
  def handle_event("select_all", _params, socket) do
    socket
    |> push_event("select_all", %{})
    |> reply(:noreply)
  end

  def handle_event("move_selected", _params, socket) do
    socket
    |> reply(:noreply)
  end
end
