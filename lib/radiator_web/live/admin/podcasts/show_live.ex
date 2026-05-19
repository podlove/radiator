defmodule RadiatorWeb.Admin.Podcasts.ShowLive do
  use RadiatorWeb, :live_view

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    podcast = Radiator.Podcasts.get_podcast_by_id!(id)

    socket =
      socket
      |> assign(:podcast, podcast)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <:breadcrumb path={~p"/admin/podcasts"}>{gettext("Podcasts")}</:breadcrumb>
      <:breadcrumb>{@podcast.title}</:breadcrumb>

      <header class="flex items-start justify-between gap-4">
        <div>
          <h1 class="text-2xl font-semibold">{@podcast.title}</h1>
          <p :if={@podcast.subtitle} class="opacity-70">{@podcast.subtitle}</p>
        </div>
        <div class="flex gap-2 shrink-0">
          <.button navigate={~p"/admin/podcasts/#{@podcast}/edit"} variant="primary">
            {gettext("Edit")}
          </.button>
          <.button
            variant="warning"
            data-confirm={gettext("Are you sure you want to delete %{title}?", title: @podcast.title)}
            phx-value-id={@podcast.id}
            phx-click="destroy-podcast"
          >
            {gettext("Delete")}
          </.button>
        </div>
      </header>

      <p :if={@podcast.summary} class="mt-4">{@podcast.summary}</p>

      <dl class="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-3">
        <.detail label={gettext("Author")} value={@podcast.author} />
        <.detail label={gettext("Language")} value={@podcast.language} />
        <.detail label={gettext("Mnemonic")} value={@podcast.mnemonic} />
        <.detail label={gettext("iTunes Type")} value={@podcast.itunes_type} />
        <.detail
          label={gettext("iTunes Category")}
          value={Enum.join(@podcast.itunes_category, ", ")}
        />
        <.detail label={gettext("License Name")} value={@podcast.license_name} />
        <.detail label={gettext("License URL")} value={@podcast.license_url} />
        <.detail label={gettext("Funding URL")} value={@podcast.funding_url} />
        <.detail label={gettext("Funding Description")} value={@podcast.funding_description} />
        <.detail
          label={gettext("Explicit")}
          value={if @podcast.explicit, do: gettext("Yes"), else: gettext("No")}
        />
        <.detail
          label={gettext("Blocked")}
          value={if @podcast.blocked, do: gettext("Yes"), else: gettext("No")}
        />
        <.detail
          label={gettext("Complete")}
          value={if @podcast.complete, do: gettext("Yes"), else: gettext("No")}
        />
      </dl>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("destroy-podcast", %{"id" => podcast_id}, socket) do
    case Radiator.Podcasts.destroy_podcast(podcast_id) do
      :ok ->
        socket =
          socket
          |> put_flash(:info, gettext("Podcast deleted"))
          |> push_navigate(to: ~p"/admin/podcasts")

        {:noreply, socket}

      {:error, error} ->
        Logger.info("Could not delete podcast #{podcast_id}: #{inspect(error)}")

        socket =
          socket
          |> put_flash(:error, gettext("Could not delete podcast"))

        {:noreply, socket}
    end
  end
end
