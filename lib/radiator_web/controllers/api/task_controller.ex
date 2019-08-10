defmodule RadiatorWeb.Api.TaskController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Task.TaskManager

  alias Radiator.Directory.{
    Editor,
    Importer
  }

  def create(conn, %{"import_podcast_feed" => import_feed_params}) do
    import_opts =
      import_feed_params
      |> Map.take(["enclosure_types", "short_id", "limit"])
      |> Enum.map(fn
        {"limit", limit} ->
          {:limit,
           case limit do
             string when is_binary(string) ->
               String.to_integer(string)

             int when is_integer(int) ->
               int
           end}

        {key, value} ->
          {String.to_existing_atom(key), value}
      end)

    with user = current_user(conn),
         {:ok, network} <- Editor.get_network(user, import_feed_params["network_id"]),
         feed_url when is_binary(feed_url) <- import_feed_params["feed_url"],
         metalove_podcast = %Metalove.Podcast{} <- Metalove.get_podcast(feed_url),
         {:ok, task_id} <- Importer.start_import_task(user, network, feed_url, import_opts),
         task <- TaskManager.get_task(task_id) do
      IO.inspect(metalove_podcast)

      conn
      |> render("show.json", task: task)
    end
  end

  def show(conn, %{"id" => task_id}) do
    with task = %Radiator.Task{} <- TaskManager.get_task(task_id) do
      conn
      |> render("show.json", task: task)
    else
      _ -> @not_found_match
    end
  end

  def delete(conn, %{"id" => task_id}) do
    with {:ended, _task} <- TaskManager.end_task(task_id) do
      send_delete_resp(conn)
    else
      @not_found_match -> send_delete_resp(conn)
      error -> error
    end
  end
end
