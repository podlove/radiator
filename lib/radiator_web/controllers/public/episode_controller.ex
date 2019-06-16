defmodule RadiatorWeb.Public.EpisodeController do
  use RadiatorWeb, :controller

  require Logger

  alias Radiator.Directory

  action_fallback RadiatorWeb.FallbackController

  def action(conn, _) do
    args = [conn, conn.params, conn.assigns]
    apply(__MODULE__, action_name(conn), args)
  end

  def index(conn, _params, %{current_podcast: podcast}) do
    podcast =
      podcast
      |> Directory.preload_episodes()

    render(conn, "index.html", podcast: podcast, episodes: podcast.episodes)
  end

  def index(_, _, _), do: {:error, :not_found}

  def show(conn, _params, %{current_episode: episode}) do
    render(conn, "show.html", episode: episode)
  end

  def show(_, _, _), do: {:error, :not_found}
end
