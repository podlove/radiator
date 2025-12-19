defmodule RadiatorWeb.Admin.Episodes.FormLive do
  use RadiatorWeb, :live_view

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    episode = Radiator.Podcasts.get_episode_by_id!(id, load: [:podcast])
    form = Radiator.Podcasts.form_to_update_episode(episode)

    podcast =
      Radiator.Podcasts.get_podcast_by_id!(episode.podcast_id,
        load: [episodes: [personas: [:person]]]
      )

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:podcast, episode.podcast)
      |> assign(:page_title, "Edit Episode")
      |> assign(:personas_options, get_personas_options(podcast))

    {:ok, socket}
  end

  def mount(%{"podcast_id" => podcast_id}, _session, socket) do
    podcast =
      Radiator.Podcasts.get_podcast_by_id!(podcast_id,
        load: [episodes: [personas: [:person]]]
      )

    form = Radiator.Podcasts.form_to_create_episode(podcast_id)

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:podcast, podcast)
      |> assign(:page_title, "New Episode")
      |> assign(:personas_options, get_personas_options(podcast))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <h1>{@page_title}</h1>
      <.simple_form
        :let={form}
        id="episode_form"
        as={:form}
        for={@form}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={form[:episode_personas]}
          type="select"
          multiple
          options={@personas_options}
          prompt="Teilnehmer auswählen"
          label={gettext("Participants")}
        />
        <.input field={form[:title]} label={gettext("Title")} />
        <.input field={form[:subtitle]} label={gettext("Subtitle")} />
        <.input field={form[:summary]} label={gettext("Summary")} />
        <.input field={form[:number]} type="number" label={gettext("Number")} />
        <.input
          field={form[:itunes_type]}
          type="select"
          options={Radiator.Podcasts.ItunesEpisodeType.values()}
          label={gettext("Itunes Type")}
        />
        <.input field={form[:duration_seconds]} type="number" label={gettext("Duration Seconds")} />
        <:actions>
          <.button variant="primary">Save</.button>
        </:actions>
      </.simple_form>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"form" => form_data}, socket) do
    socket = update(socket, :form, &AshPhoenix.Form.validate(&1, form_data))
    {:noreply, socket}
  end

  def handle_event("save", %{"form" => form_data}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: form_data) do
      {:ok, episode} ->
        socket =
          socket
          |> put_flash(:info, gettext("Episode saved"))
          |> push_navigate(to: ~p"/admin/podcasts/#{socket.assigns.podcast}/episodes/#{episode}")

        {:noreply, socket}

      {:error, form} ->
        socket =
          socket
          |> put_flash(:error, gettext("Could not save episode"))
          |> assign(:form, form)

        Logger.error("Could not save episode: #{inspect(form)}")

        {:noreply, socket}
    end
  end

  defp get_personas_options(%{episodes: episodes}) do
    episodes
    |> Enum.flat_map(& &1.personas)
    |> Enum.map(& &1.person)
    |> Enum.uniq_by(& &1.id)
    |> Enum.map(&{&1.email, &1.id})
  end
end
