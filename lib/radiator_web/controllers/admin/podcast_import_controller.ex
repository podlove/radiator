defmodule RadiatorWeb.Admin.PodcastImportController do
  use RadiatorWeb, :controller

  alias Radiator.Directory.{
    Importer,
    Editor,
    Podcast
  }

  alias Radiator.Task.TaskManager

  action_fallback RadiatorWeb.FallbackController

  def new(conn, _params) do
    render(conn, "new.html")
  end

  # TODO
  # needs preview, options and progress display
  def create(conn, %{"feed" => %{"feed_url" => url}}) do
    with user <- current_user(conn),
         network <- conn.assigns.current_network,
         feed_url when is_binary(feed_url) <- url,
         _metalove_podcast = %Metalove.Podcast{} <- Metalove.get_podcast(feed_url),
         {:ok, task_id} <- Importer.start_import_task(user, network, feed_url),
         task <- busy_wait_on_task_setup(task_id, 5_000),
         {Podcast, podcast_id} <- task.description.subject,
         {:ok, podcast} <- Editor.get_podcast(user, podcast_id) do
      redirect(conn,
        to: Routes.admin_network_podcast_path(conn, :show, podcast.network_id, podcast.id)
      )
    end
  end

  defp busy_wait_on_task_setup(task_id, timeout) do
    task = TaskManager.get_task(task_id)

    with %Radiator.Task{state: :setup} <- task do
      cond do
        timeout <= 0 ->
          task

        true ->
          :timer.sleep(1_000)
          busy_wait_on_task_setup(task_id, timeout - 1_000)
      end
    else
      task -> task
    end
  end
end
