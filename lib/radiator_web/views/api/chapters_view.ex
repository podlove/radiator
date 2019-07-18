defmodule RadiatorWeb.Api.ChaptersView do
  use RadiatorWeb, :view

  alias HAL.{Document, Link, Embed}
  alias Radiator.AudioMeta.Chapter

  def render("index.json", assigns) do
    %Document{}
    |> Document.add_embed(%Embed{
      resource: "rad:chapter",
      embed:
        Enum.map(assigns[:chapters], fn chapter ->
          render(__MODULE__, "chapter.json", Map.put(assigns, :chapter, chapter))
        end)
    })
  end

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
      audio_id: chapter.audio_id,
      start: chapter.start,
      title: chapter.title,
      link: chapter.link,
      image: Chapter.image_url(chapter)
    })
  end
end
