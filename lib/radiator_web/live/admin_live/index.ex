defmodule RadiatorWeb.AdminLive.Index do
  use RadiatorWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> reply(:ok)
  end
end
