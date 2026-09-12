defmodule RadiatorWeb.Admin.EpisodeLive.Form do
  use RadiatorWeb, :live_view

  require Ash.Query

  alias AshPhoenix.Form
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.EpisodeType
  alias Radiator.Podcasts.Podcast
  alias RadiatorWeb.Formatting

  @impl true
  def mount(%{"podcast_id" => podcast_id} = params, _session, socket) do
    actor = socket.assigns.current_user
    podcast = Ash.get!(Podcast, podcast_id, load: [:display_title], actor: actor)
    episode = load_episode(podcast, params["id"], actor)

    socket
    |> assign(podcast: podcast, episode: episode)
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign(form: build_form(podcast, episode, actor))
    |> ok()
  end

  defp load_episode(_podcast, nil, _actor), do: nil

  defp load_episode(podcast, id, actor) do
    Episode
    |> Ash.Query.filter(id == ^id and podcast_id == ^podcast.id)
    |> Ash.read_one!(actor: actor, not_found_error?: true)
  end

  defp page_title(:edit), do: gettext("Episode bearbeiten")
  defp page_title(_live_action), do: gettext("Neue Episode")

  # The podcast comes from the route, not from the form.
  defp build_form(podcast, nil, actor) do
    Episode
    |> Form.for_create(:create,
      as: "episode",
      actor: actor,
      transform_params: fn _form, params, _type -> Map.put(params, "podcast_id", podcast.id) end
    )
    |> to_form()
  end

  defp build_form(_podcast, episode, actor) do
    episode |> Form.for_update(:update, as: "episode", actor: actor) |> to_form()
  end

  @impl true
  def handle_event("validate", %{"episode" => params}, socket) do
    socket |> assign(form: Form.validate(socket.assigns.form, params)) |> noreply()
  end

  def handle_event("add-form", %{"path" => path}, socket) do
    socket |> assign(form: Form.add_form(socket.assigns.form, path)) |> noreply()
  end

  def handle_event("remove-form", %{"path" => path}, socket) do
    socket |> assign(form: Form.remove_form(socket.assigns.form, path)) |> noreply()
  end

  def handle_event("save", %{"episode" => params}, socket) do
    case Form.submit(socket.assigns.form, params: params) do
      {:ok, _episode} ->
        socket
        |> put_flash(:info, saved_message(socket.assigns.live_action))
        |> push_navigate(to: ~p"/admin/podcasts/#{socket.assigns.podcast}")
        |> noreply()

      {:error, form} ->
        socket |> assign(form: form) |> noreply()
    end
  end

  defp saved_message(:edit), do: gettext("Episode gespeichert.")
  defp saved_message(_live_action), do: gettext("Episode angelegt.")
end
