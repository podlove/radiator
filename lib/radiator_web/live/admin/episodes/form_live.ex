defmodule RadiatorWeb.Admin.Episodes.FormLive do
  use RadiatorWeb, :live_view

  require Logger

  alias AshPhoenix.Form
  alias Radiator.Podcasts

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    episode = Podcasts.get_episode_by_id!(id, load: [:participants])
    podcast = Podcasts.get_podcast_by_id!(episode.podcast_id)

    form =
      episode
      |> Form.for_update(:update,
        domain: Podcasts,
        forms: participant_forms(data: fn ep -> ep.participants end)
      )

    socket
    |> assign(:form, to_form(form))
    |> assign(:podcast, podcast)
    |> assign(:page_title, "Edit Episode")
    |> assign_candicates()
    |> ok()
  end

  def mount(%{"podcast_id" => podcast_id}, _session, socket) do
    podcast = Podcasts.get_podcast_by_id!(podcast_id)

    form =
      Podcasts.Episode
      |> Form.for_create(:create,
        domain: Podcasts,
        forms: participant_forms(),
        params: %{podcast_id: podcast.id}
      )

    socket
    |> assign(:form, to_form(form))
    |> assign(:podcast, podcast)
    |> assign(:page_title, "New Episode")
    |> assign_candicates()
    |> ok()
  end

  @impl Phoenix.LiveView
  def handle_event("add_participant", _params, socket) do
    form = Form.add_form(socket.assigns.form, :participants)

    socket
    |> assign(:form, form)
    |> noreply()
  end

  def handle_event("remove_participant", %{"path" => path}, socket) do
    form = Form.remove_form(socket.assigns.form, path)

    socket
    |> assign(:form, form)
    |> assign_candicates()
    |> noreply()
  end

  def handle_event(
        "connect_participant",
        %{"handle" => handle, "public_name" => public_name},
        socket
      ) do
    form =
      Form.add_form(socket.assigns.form, :participants,
        params: %{public_name: public_name, handle: handle}
      )

    socket
    |> assign(:form, form)
    |> assign_candicates()
    |> noreply()
  end

  def handle_event("validate", %{"form" => form_params}, socket) do
    form = Form.validate(socket.assigns.form, form_params)

    socket
    |> assign(:form, form)
    |> assign_candicates()
    |> noreply()
  end

  def handle_event("save", %{"form" => form_data}, socket) do
    case Form.submit(socket.assigns.form, params: form_data) do
      {:ok, episode} ->
        socket
        |> put_flash(:info, gettext("Episode saved"))
        |> push_navigate(to: ~p"/admin/podcasts/#{socket.assigns.podcast}/episodes/#{episode}")
        |> noreply()

      {:error, form} ->
        Logger.error("Could not save episode: #{inspect(form)}")

        socket
        |> put_flash(:error, gettext("Could not save episode"))
        |> assign(:form, form)
        |> noreply()
    end
  end

  defp participant_forms(opts \\ []) do
    [
      participants:
        [
          type: :list,
          resource: Radiator.People.Persona,
          create_action: :create,
          update_action: :update
        ] ++ opts
    ]
  end

  defp assign_candicates(socket) do
    reject_handles =
      socket.assigns.form
      |> Form.value(:participants)
      |> Enum.map(&Form.value(&1, :handle))

    candicates =
      socket.assigns.podcast.id
      |> Podcasts.read_podcast_participants()
      |> Enum.reject(&(&1.handle in reject_handles))

    socket
    |> assign(:candicates, candicates)
  end
end
