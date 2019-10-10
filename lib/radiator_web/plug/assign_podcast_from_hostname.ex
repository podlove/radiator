defmodule RadiatorWeb.Plug.AssignPodcastFromHostname do
  @behaviour Plug

  import Plug.Conn

  alias Radiator.Directory
  alias Radiator.Directory.Episode

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case Map.get(conn.path_params, "episode_slug") do
      nil ->
        conn

      slug ->
        case Directory.get_episode_by_slug(conn.assigns[:current_podcast], slug) do
          %Episode{} = episode ->
            assign(conn, :current_episode, episode)

          _ ->
            conn
        end
    end
  end
end
