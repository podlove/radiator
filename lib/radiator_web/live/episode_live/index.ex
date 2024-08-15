defmodule RadiatorWeb.EpisodeLive.Index do
  use RadiatorWeb, :live_view
  require Logger

  alias Radiator.Outline.Dispatch

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  alias Radiator.Outline.NodeRepository
  alias Radiator.Podcast
  alias Radiator.Podcast.Episode
  alias RadiatorWeb.OutlineComponents

  @impl true
  def mount(%{"show" => show_id} = params, _session, socket) do
    show = Podcast.get_show!(show_id, preload: :episodes)
    episode = get_selected_episode(params)

    socket
    |> assign(:page_title, show.title)
    # |> assign(:page_description, "")
    |> assign(:show, show)
    |> assign(:episodes, show.episodes)
    |> assign(action: nil, episode: nil, form: nil)
    |> stream_configure(:event_logs, dom_id: & &1.uuid)
    |> stream(:event_logs, get_event_logs(episode))
    |> reply(:ok)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    episode = get_selected_episode(params)

    if connected?(socket) do
      Dispatch.subscribe()
    end

    socket =
      if connected?(socket) do
        # TODO: Not too sure wether we should use one key for all episodes or one key per episode.
        storage_key = "radiator-episode-#{episode.id}"

        socket
        |> assign(:user_session_info, storage_key)
        # request the browser to restore any state it has for this key.
        |> push_event("restore", %{key: storage_key, event: "restoreSettings"})
      else
        socket
      end

    socket
    |> apply_action(socket.assigns.live_action, params)
    |> assign(:selected_episode, episode)
    |> reply(:noreply)
  end

  defp restore_from_token(nil), do: {:ok, nil}

  defp restore_from_token(token) do
    salt = Application.get_env(:radiator, RadiatorWeb.Endpoint)[:live_view][:signing_salt]
    # Max age is 1 day. 86,400 seconds
    case Phoenix.Token.decrypt(RadiatorWeb.Endpoint, salt, token, max_age: 86_400) do
      {:ok, data} ->
        {:ok, data}

      {:error, reason} ->
        # handles `:invalid`, `:expired` and possibly other things?
        {:error, "Failed to restore previous state. Reason: #{inspect(reason)}."}
    end
  end

  defp serialize_to_token(state_data) do
    salt = Application.get_env(:radiator, RadiatorWeb.Endpoint)[:live_view][:signing_salt]
    Phoenix.Token.encrypt(RadiatorWeb.Endpoint, salt, state_data)
  end

  # Push a websocket event down to the browser's JS hook.
  # Clear any settings for the current my_storage_key.
  defp clear_browser_storage(socket) do
    push_event(socket, "clear", %{key: socket.assigns.my_storage_key})
  end

  @impl true
  # Pushed from JS hook. Server requests it to send up any
  # stored settings for the key.
  def handle_event("restoreSettings", token_data, socket) when is_binary(token_data) do
    socket =
      case restore_from_token(token_data) do
        {:ok, nil} ->
          # do nothing with the previous state
          socket

        {:ok, restored} ->
          socket
          |> assign(:state, restored)

        {:error, reason} ->
          # We don't continue checking. Display error.
          # Clear the token so it doesn't keep showing an error.
          socket
          |> put_flash(:error, reason)
          |> clear_browser_storage()
      end

    {:noreply, socket}
  end

  def handle_event("restoreSettings", _token_data, socket) do
    # No expected token data received from the client
    Logger.debug("No LiveView SessionStorage state to restore")
    {:noreply, socket}
  end

  def handle_event("something_happened_and_i_want_to_store", _params, socket) do
    state_to_store = socket.assigns.state

    socket =
      socket
      |> push_event("store", %{
        key: socket.assigns.my_storage_key,
        data: serialize_to_token(state_to_store)
      })

    {:noreply, socket}
  end

  def handle_event("new_episode", _params, socket) do
    show = socket.assigns.show
    number = Podcast.get_next_episode_number(show.id)

    episode = %Podcast.Episode{}
    changeset = Episode.changeset(episode, %{number: number})

    socket
    |> assign(:action, :new_episode)
    |> assign(:episode, episode)
    |> assign(:form, to_form(changeset))
    |> reply(:noreply)
  end

  def handle_event("validate", %{"episode" => params}, socket) do
    changeset = Episode.changeset(socket.assigns.episode, params)

    socket
    |> assign(:form, to_form(changeset, action: :validate))
    |> reply(:noreply)
  end

  def handle_event("save", %{"episode" => params}, socket) do
    params = Map.put(params, "show_id", socket.assigns.show.id)

    save_episode(socket, socket.assigns.action, params)
  end

  @impl true
  def handle_info(%{uuid: <<_::binary-size(36)>> <> ":" <> id} = event, %{id: id} = socket) do
    socket
    |> stream_event(event)
    |> reply(:noreply)
  end

  def handle_info(%NodeInsertedEvent{} = event, socket), do: proxy_event(event, socket)
  def handle_info(%NodeContentChangedEvent{} = event, socket), do: proxy_event(event, socket)
  def handle_info(%NodeMovedEvent{} = event, socket), do: proxy_event(event, socket)
  def handle_info(%NodeDeletedEvent{} = event, socket), do: proxy_event(event, socket)

  defp proxy_event(event, socket) do
    send_update(RadiatorWeb.OutlineComponent, id: "outline", event: event)

    socket
    |> stream_event(event)
    |> reply(:noreply)
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
        NodeRepository.create_node(%{
          "uuid" => Ecto.UUID.generate(),
          "creator_id" => socket.assigns.current_user.id,
          "episode_id" => episode.id
        })

        socket
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
        socket
        |> put_flash(:info, "Episode updated")
        |> push_patch(to: ~p"/admin/podcast/#{socket.assigns.show}/#{episode}")
        |> reply(:noreply)

      {:error, %Ecto.Changeset{} = changeset} ->
        socket |> assign(form: to_form(changeset)) |> reply(:noreply)
    end
  end

  defp get_selected_episode(%{"episode" => episode_id}) do
    Podcast.get_episode!(episode_id)
  end

  defp get_selected_episode(%{"show" => show_id}) do
    Podcast.get_current_episode_for_show(show_id)
  end

  def get_event_logs(nil), do: []

  def get_event_logs(_episode) do
    # EventStore.list_event_data_by_episode(episode.id)
    []
  end

  defp stream_event(socket, event) do
    socket
    |> stream_insert(:event_logs, event, at: 0)
  end
end
