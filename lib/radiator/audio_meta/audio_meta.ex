defmodule Radiator.AudioMeta do
  @moduledoc """
  The Episode Metadata context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias Radiator.Repo
  alias Radiator.Directory.Audio
  alias Radiator.AudioMeta.Chapter
  alias Radiator.Media.ChapterImage

  def list_chapters(%Audio{} = audio) do
    from(
      c in Chapter,
      where: c.audio_id == ^audio.id,
      order_by: [asc: c.start],
      preload: [:audio]
    )
    |> Repo.all()
  end

  def get_next_chapter(chapter = %Chapter{}) do
    from(
      c in Chapter,
      where: c.audio_id == ^chapter.audio_id and c.start > ^chapter.start,
      order_by: [asc: c.start],
      limit: 1
    )
    |> Repo.one()
  end

  def delete_chapter(chapter = %Chapter{}) do
    delete_chapter_image(chapter)
    Repo.delete(chapter)
  end

  def delete_chapters(%Audio{} = audio) do
    audio = Repo.preload(audio, :chapters)

    # delete chapter images from storage
    Enum.each(audio.chapters, &delete_chapter_image/1)

    # delete chapters
    from(
      c in Chapter,
      where: c.audio_id == ^audio.id
    )
    |> Repo.delete_all()
  end

  def delete_chapter_image(%Chapter{image: nil}) do
    {:ok, :no_image_to_delete}
  end

  def delete_chapter_image(chapter = %Chapter{image: image}) do
    ChapterImage.delete({image, chapter})
    {:ok, :deleted}
  end

  def create_chapter(%Audio{} = audio, attrs) do
    {update_attrs, insert_attrs} = Map.split(attrs, [:image, "image"])

    insert =
      %Chapter{}
      |> Chapter.changeset(insert_attrs)
      |> Ecto.Changeset.put_assoc(:audio, audio)

    Multi.new()
    |> Multi.insert(:chapter, insert)
    |> Multi.update(:chapter_updated, fn %{chapter: chapter} ->
      Chapter.changeset(chapter, update_attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{chapter_updated: chapter}} -> {:ok, chapter}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_chapter(chapter = %Chapter{}, attrs) do
    chapter
    |> Chapter.changeset(attrs)
    |> Repo.update()
  end

  def set_chapters(%Audio{} = audio, input, type)
      when is_binary(input) and type in [:psc, :json, :mp4chaps] do
    chapters = Chapters.decode(input, type)

    delete_chapters(audio)

    chapters
    |> Enum.each(fn chapter ->
      create_chapter(audio, %{
        start: chapter.start,
        title: chapter.title,
        link: chapter.href,
        image: chapter.image
      })
    end)

    {:ok, audio}
  end
end
