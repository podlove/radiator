defmodule RadiatorWeb.OutlineLive.Index do
  use RadiatorWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Outline")
    |> reply(:ok)
  end
end
