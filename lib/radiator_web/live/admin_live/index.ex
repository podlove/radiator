defmodule RadiatorWeb.AdminLive.Index do
  use RadiatorWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Admin Dashboard")
    |> reply(:ok)
  end
end
