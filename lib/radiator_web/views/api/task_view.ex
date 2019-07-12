defmodule RadiatorWeb.Api.TaskView do
  use RadiatorWeb, :view
  alias __MODULE__
  alias HAL.{Document, Link, Embed}

  def render("show.json", assigns) do
    render(TaskView, "podcast_feed_import_task.json", assigns)
  end

  def render("podcast_feed_import_task.json", %{task: task = %{subject: subject}, conn: conn}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_task_path(conn, :show, task.id)
    })
    |> Document.add_link(%Link{
      rel: "rad:subject",
      href: Routes.api_podcast_path(conn, :show, subject.id)
    })
    |> Document.add_properties(task)
  end
end
