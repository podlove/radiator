defmodule RadiatorWeb.Admin.Shows.ShowLive do
  use RadiatorWeb, :live_view

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    show = Radiator.Podcasts.get_show_by_id!(id)

    socket =
      socket
      |> assign(:show, show)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <h1>{@show.title}</h1>
      <h2 :if={@show.subtitle}>{@show.subtitle}</h2>
      <.button
        variant="danger"
        data-confirm={gettext("Are you sure you want to delete %{title}?", title: @show.title)}
        phx-value-id={@show.id}
        phx-click="destroy-show"
      >
        {gettext("Delete Show")}
      </.button>
      <.button navigate={~p"/admin/shows/#{@show}/edit"} variant="primary">
        {gettext("Edit Show")}
      </.button>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("destroy-show", %{"id" => show_id}, socket) do
    case Radiator.Podcasts.destroy_show(show_id) do
      :ok ->
        socket =
          socket
          |> put_flash(:info, gettext("Show deleted"))
          |> push_navigate(to: ~p"/admin/shows")

        {:noreply, socket}

      {:error, error} ->
        Logger.info("Could not delete show #{show_id}: #{inspect(error)}")

        socket =
          socket
          |> put_flash(:error, gettext("Could not delete show"))

        {:noreply, socket}
    end
  end
end
