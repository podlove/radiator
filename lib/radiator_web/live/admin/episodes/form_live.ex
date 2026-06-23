defmodule RadiatorWeb.Admin.Episodes.FormLive do
  use RadiatorWeb, :live_view

  require Logger

  alias AshPhoenix.Form
  alias Radiator.Podcasts

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    episode = Podcasts.get_episode_by_id!(id, load: [:participants, :scheduling])
    podcast = Podcasts.get_podcast_by_id!(episode.podcast_id)

    form =
      episode
      |> Form.for_update(:update,
        domain: Podcasts,
        forms: [auto?: true]
      )

    socket
    |> assign(:form, to_form(form))
    |> assign(:podcast, podcast)
    |> assign(:cancel_path, ~p"/admin/podcasts/#{podcast}/episodes/#{episode}")
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
        forms: [auto?: true],
        params: %{podcast_id: podcast.id}
      )

    socket
    |> assign(:form, to_form(form))
    |> assign(:podcast, podcast)
    |> assign(:cancel_path, ~p"/admin/podcasts/#{podcast}/episodes")
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
        %{"handle" => handle} = params,
        socket
      ) do
    form =
      Form.add_form(socket.assigns.form, :participants,
        params: %{handle: handle, email: Map.get(params, "email")}
      )

    socket
    |> assign(:form, form)
    |> assign_candicates()
    |> noreply()
  end

  def handle_event("add_proposal", _params, socket) do
    case socket.assigns.current_user do
      %{id: user_id} ->
        form =
          socket.assigns.form
          |> ensure_scheduling_form(user_id)
          |> Form.add_form([:scheduling, :proposals],
            params: %{created_by_user_id: user_id}
          )

        socket
        |> assign(:form, form)
        |> noreply()

      _ ->
        socket
        |> put_flash(:error, gettext("You need to be signed in before you can propose dates."))
        |> noreply()
    end
  end

  def handle_event("remove_proposal", %{"path" => path}, socket) do
    form = Form.remove_form(socket.assigns.form, path)

    socket
    |> assign(:form, form)
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
        {:ok, invited} = Podcasts.invite_new_participants(episode)

        socket
        |> put_flash(:info, save_flash(invited))
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

  defp save_flash([]), do: gettext("Episode saved")

  defp save_flash(invited),
    do: gettext("Episode saved, %{count} invitation(s) sent", count: length(invited))

  # Make sure a (single) scheduling form exists before adding proposals to it.
  # On a new episode there is no scheduling yet, so we create one owned by the
  # current user the first time a proposal is added.
  defp ensure_scheduling_form(form, owner_user_id) do
    case Form.value(form, :scheduling) do
      nil -> Form.add_form(form, :scheduling, params: %{owner_user_id: owner_user_id})
      _ -> form
    end
  end

  defp assign_candicates(socket) do
    reject_handles =
      socket.assigns.form
      |> Form.value(:participants)
      |> List.wrap()
      |> Enum.map(&Form.value(&1, :handle))

    candicates =
      socket.assigns.podcast.id
      |> Podcasts.read_podcast_participants()
      |> Enum.reject(&(&1.handle in reject_handles))

    socket
    |> assign(:candicates, candicates)
  end
end
