defmodule RadiatorWeb.Api.TaskView do
  use RadiatorWeb, :view
  alias __MODULE__
  alias HAL.{Document, Link}
  alias Radiator.Directory.Network

  def render("show.json", assigns) do
    render(TaskView, "podcast_feed_import_task.json", assigns)
  end

  def render("podcast_feed_import_task.json", %{task: task = %Radiator.Task{}, conn: conn}) do
    document =
      %Document{}
      |> Document.add_link(%Link{
        rel: "self",
        href: Routes.api_task_path(conn, :show, task.id)
      })
      |> Document.add_properties(
        Map.take(task, [:id, :progress, :total, :start_time, :end_time, :state])
      )
      |> Document.add_property(:title, task.description[:title])

    document =
      case task.description[:subject] do
        {Network, network_id} ->
          Document.add_link(document, %Link{
            rel: "rad:subject",
            href: Routes.api_network_path(conn, :show, network_id)
          })

        _ ->
          document
      end

    document
  end
end
