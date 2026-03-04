defmodule RadiatorWeb.Admin.Episodes.FormLive do
  use RadiatorWeb, :live_view

  require Logger

  alias AshPhoenix.Form
  alias Radiator.Podcasts

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    episode = Podcasts.get_episode_by_id!(id)

    load = [episodes: [participants: [:person]]]
    podcast = Podcasts.get_podcast_by_id!(episode.podcast_id, load: load)

    form =
      Podcasts.form_to_update_episode(episode,
        as: "episode",
        forms: [
          participants: [type: :list, resource: Radiator.People.Persona, create_action: :create]
        ]
      )

    # Episode
    # |> Form.for_create(:create,
    #   domain: Podcasts,
    #   forms: [
    #     participants: [type: :list, resource: Radiator.People.Persona, create_action: :create]
    #   ]
    # )

    socket
    |> assign(:form, to_form(form))
    |> assign(:podcast, podcast)
    |> assign(:page_title, "Edit Episode")
    |> ok()
  end

  def mount(%{"podcast_id" => podcast_id}, _session, socket) do
    load = [episodes: [participants: [:person]]]
    podcast = Podcasts.get_podcast_by_id!(podcast_id, load: load)

    # Warum laden wir das?
    # Wir wollen alle Persons/Personas haben, die jemand in diesem Podcast (egal in welcher Episode) waren
    # (für eine Vorschlagsliste)

    # Better but not working at the moment
    # form =
    #   Podcasts.form_to_create_episode(
    #     as: "episode",
    #     forms: [
    #       participants: [type: :list, resource: Radiator.People.Persona, create_action: :create]
    #     ]
    #   )

    form =
      Podcasts.Episode
      |> Form.for_create(:create,
        domain: Podcasts,
        forms: [
          participants: [type: :list, resource: Radiator.People.Persona, create_action: :create]
        ],
        params: %{podcast_id: podcast.id}
      )

    socket
    |> assign(:form, to_form(form))
    |> assign(:podcast, podcast)
    |> assign(:page_title, "New Episode")
    |> ok()
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
        <.inputs_for :let={participant} field={@form[:participants]}>
          <.input
            field={participant[:public_name]}
            type="text"
            label="public_name"
          />
          <.input
            field={participant[:handle]}
            type="text"
            label="handle"
          />
        </.inputs_for>
        <.button type="button" phx-click="add_participant">Add participant</.button>

        <.input field={form[:podcast_id]} label={gettext("Podcast Id")} />
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
  def handle_event("add_participant", _params, socket) do
    form = Form.add_form(socket.assigns.form, :participants)

    socket
    |> assign(:form, form)
    |> noreply()
  end

  def handle_event("validate", %{"form" => form_data}, socket) do
    socket = update(socket, :form, &Form.validate(&1, form_data))
    {:noreply, socket}
  end

  def handle_event("save", %{"form" => form_data}, socket) do
    case Form.submit(socket.assigns.form, params: form_data) do
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

  # defp get_personas_options(%{episodes: episodes}) do
  #   episodes
  #   |> Enum.flat_map(& &1.personas)
  #   |> Enum.map(& &1.person)
  #   |> Enum.uniq_by(& &1.id)
  #   |> Enum.map(&{&1.email, &1.id})
  # end
end
