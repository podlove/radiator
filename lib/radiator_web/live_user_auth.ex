defmodule RadiatorWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  use RadiatorWeb, :verified_routes

  alias AshAuthentication.Phoenix.LiveSession

  defp assign_active_podcast(params, _uri, socket) do
    podcast_id = params["podcast_id"] || params["id"]

    socket =
      if known_podcast?(podcast_id, socket) do
        Phoenix.Component.assign(socket, :active_podcast_id, podcast_id)
      else
        Phoenix.Component.assign(socket, :active_podcast_id, nil)
      end

    {:cont, socket}
  end

  defp known_podcast?(nil, _socket), do: false

  defp known_podcast?(id, socket) do
    Enum.any?(socket.assigns[:sidebar_podcasts] || [], &(&1.id == id))
  end

  # This is used for nested liveviews to fetch the current user.
  # To use, place the following at the top of that liveview:
  # on_mount {RadiatorWeb.LiveUserAuth, :current_user}
  def on_mount(:current_user, _params, session, socket) do
    {:cont, LiveSession.assign_new_resources(socket, session)}
  end

  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_user_required, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

    def on_mount(:sidebar_navigation, _params, _session, socket) do
      socket =
        socket
        |> assign_new(:sidebar_podcasts, fn ->
          Radiator.Podcasts.read_podcasts!(nil, load: [:episodes])
        end)
        |> assign_new(:active_podcast_id, fn -> nil end)
        |> Phoenix.LiveView.attach_hook(
          :assign_active_podcast,
          :handle_params,
          &assign_active_podcast/3
        )

      {:cont, socket}
    end
end
