defmodule RadiatorWeb.Plug.AssignFromPublicSlugs do
  @behaviour Plug

  import Plug.Conn
  alias Radiator.Directory
  alias Radiator.Directory.{Podcast, Episode}

  #  alias RadiatorWeb.Router.Helpers, as: Routes

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case Map.get(conn.path_params, "podcast_slug") do
      nil ->
        conn

      slug ->
        case Directory.get_podcast_by_slug(slug) do
          %Podcast{} = podcast ->
            assign(conn, :current_podcast, podcast)
            |> assign_episode_from_slug(podcast)

          _ ->
            conn
        end
    end
  end

  defp assign_episode_from_slug(conn, podcast) do
    case Map.get(conn.path_params, "episode_slug") do
      nil ->
        conn

      slug ->
        case Directory.get_episode_by_slug(podcast, slug) do
          %Episode{} = episode ->
            assign(conn, :current_episode, episode)

          _ ->
            conn
        end
    end
  end
end
