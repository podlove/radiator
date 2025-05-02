defmodule RadiatorWeb.EpisodeLive.Index do
  use RadiatorWeb, :live_view

  import Extension.Map

  alias Radiator.Outline.Dispatch

  alias Radiator.Podcast
  alias Radiator.Podcast.Episode
  alias RadiatorWeb.OutlineComponents
  alias RadiatorWeb.PodcastComponents

  @impl true
  def mount(%{"show" => show_id} = _params, _session, socket) do
    show = Podcast.get_show_preloaded!(show_id)

    socket
    |> assign(:page_title, show.title)
    |> assign(:page_description, show.description)
    |> assign(:show, show)
    |> assign(:episodes, show.episodes)
    |> assign(action: nil, episode: nil, form: nil)
    |> reply(:ok)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    episode = get_selected_episode(params)

    socket
    |> apply_action(socket.assigns.live_action, params)
    |> assign(:selected_episode, episode)
    |> reply(:noreply)
  end

  @impl true
  def handle_event("validate", %{"episode" => params}, socket) do
    changeset = Episode.changeset(socket.assigns.episode, params)

    socket
    |> assign(:form, to_form(changeset, action: :validate))
    |> reply(:noreply)
  end

  def handle_event("save", %{"episode" => params}, socket) do
    params = Map.put(params, "show_id", socket.assigns.show.id)

    save_episode(socket, socket.assigns.live_action, params)
  end

  def handle_event("delete", params, socket) do
    delete_episode(socket, params)
  end

  defp apply_action(socket, :new, %{"show" => show_id}) do
    number = Podcast.get_next_episode_number(show_id)

    episode = %Podcast.Episode{}
    changeset = Episode.changeset(episode, %{number: number})

    socket
    |> assign(:title, "New Episode")
    |> assign(:episode, episode)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :edit, %{"episode" => episode_id}) do
    episode = Podcast.get_episode!(episode_id)
    changeset = Podcast.change_episode(episode, %{})

    socket
    |> assign(:title, "Edit Episode")
    |> assign(:episode, episode)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  defp save_episode(socket, :new, params) do
    case Podcast.create_episode(params) do
      {:ok, episode} ->
        Dispatch.insert_node(
          %{"episode_id" => episode.id, "content" => ""},
          socket.assigns.current_user.id,
          Ecto.UUID.generate()
        )

        show =
          Podcast.reload_assoc(socket.assigns.show,
            episodes: Podcast.list_available_episodes_query()
          )

        socket
        |> assign(:show, show)
        |> assign(:episodes, show.episodes)
        |> put_flash(:info, "Episode created")
        |> push_patch(to: ~p"/admin/podcast/#{socket.assigns.show}/#{episode}")
        |> reply(:noreply)

      {:error, %Ecto.Changeset{} = changeset} ->
        socket |> assign(form: to_form(changeset)) |> reply(:noreply)
    end
  end

  defp save_episode(socket, :edit, params) do
    case Podcast.update_episode(socket.assigns.episode, params) do
      {:ok, episode} ->
        show =
          Podcast.reload_assoc(socket.assigns.show,
            episodes: Podcast.list_available_episodes_query()
          )

        socket
        |> assign(:show, show)
        |> assign(:episodes, show.episodes)
        |> put_flash(:info, "Episode updated")
        |> push_patch(to: ~p"/admin/podcast/#{socket.assigns.show}/#{episode}")
        |> reply(:noreply)

      {:error, %Ecto.Changeset{} = changeset} ->
        socket |> assign(form: to_form(changeset)) |> reply(:noreply)
    end
  end

  defp delete_episode(socket, %{"id" => id}) do
    id
    |> Podcast.get_episode!()
    |> Podcast.delete_episode()
    |> case do
      {:ok, _episode} ->
        show =
          Podcast.reload_assoc(socket.assigns.show,
            episodes: Podcast.list_available_episodes_query()
          )

        socket
        |> assign(:show, show)
        |> assign(:episodes, show.episodes)
        |> put_flash(:info, "Episode deleted")
        |> push_patch(to: ~p"/admin/podcast/#{socket.assigns.show}")
        |> reply(:noreply)

      {:error, _changeset} ->
        socket
        |> put_flash(:error, "Failed to delete episode")
        |> reply(:noreply)
    end
  end

  defp get_selected_episode(%{"episode" => episode_id}) do
    Podcast.get_episode!(episode_id)
  end

  defp get_selected_episode(%{"show" => show_id}) do
    Podcast.get_current_episode_for_show(show_id)
  end
end
