defmodule RadiatorWeb.EpisodeLive.Index do
  use RadiatorWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> ok()
  end
end
