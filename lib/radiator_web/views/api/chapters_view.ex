defmodule RadiatorWeb.Api.ChaptersView do
  use RadiatorWeb, :view

  alias HAL.{Document, Link}
  alias Radiator.AudioMeta.Chapter

  def render("show.json", assigns) do
    render(__MODULE__, "chapter.json", assigns)
  end

  def render("chapter.json", %{conn: conn, chapter: chapter, audio: audio}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_audio_chapters_path(conn, :show, audio.id, chapter.start)
    })
    |> Document.add_properties(%{
      title: chapter.title,
      start: chapter.start,
      link: chapter.link,
      image: Chapter.image_url(chapter)
    })
  end
end
