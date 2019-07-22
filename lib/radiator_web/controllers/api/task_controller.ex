defmodule RadiatorWeb.Api.TaskController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  def create(conn, %{"import_podcast_feed" => params}) do
    with user = current_user(conn),
         {:ok, network} <- Editor.get_network(user, params["network_id"]),
         feed_url when is_binary(feed_url) <- params["feed_url"],
         metalove_podcast = %Metalove.Podcast{} <- Metalove.get_podcast(feed_url) do
      IO.inspect(metalove_podcast)

      episodes = Metalove.PodcastFeed.get_by_feed_url(metalove_podcast.main_feed_url).episodes

      {:ok, %{podcast: podcast}} =
        Radiator.Directory.Importer.import_from_url(user, network, feed_url)

      IO.inspect(podcast)

      task =
        dummy_task(5)
        |> Map.put(:title, "Import of '#{feed_url}' into #{network.title}")
        |> update_in([:progress, :total], fn _ -> length(episodes) end)

      conn
      |> render("show.json", task: task)
    end
  end

  def show(conn, %{"id" => id}) do
    task = dummy_task(id)

    conn
    |> render("show.json", task: task)
  end

  defp dummy_task(id) do
    %{
      id: id,
      title: "Import of https://cre.fm",
      progress: %{
        completed: 4,
        total: 10
      },
      subject: %{
        id: 1,
        type: :Podcast
      }
    }
  end
end
