defmodule Radiator.AudioMeta do
  @moduledoc """
  The Episode Metadata context.
  """

  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Directory.Audio
  alias Radiator.AudioMeta.Chapter

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(Chapter, args) do
    chapters_query(args)
  end

  def query(queryable, _) do
    queryable
  end

  defp chapters_query(args) do
    Enum.reduce(args, Chapter, fn
      {:order, order}, query -> query |> order_by({^order, :start})
    end)
  end

  def list_chapters(%Audio{} = audio) do
    from(
      c in Chapter,
      where: c.audio_id == ^audio.id,
      order_by: [asc: c.start]
    )
    |> Repo.all()
  end

  def delete_chapters(%Audio{} = audio) do
    from(
      c in Chapter,
      where: c.audio_id == ^audio.id
    )
    |> Repo.delete_all()
  end

  def create_chapter(%Audio{} = audio, attrs) do
    %Chapter{}
    |> Chapter.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:audio, audio)
    |> Repo.insert()
  end

  def set_chapters(%Audio{} = audio, input, type)
      when is_binary(input) and type in [:psc, :json, :mp4chaps] do
    chapters = Chapters.decode(input, type)

    # transaction:
    # - delete existing chapters
    # - insert all new chapters

    delete_chapters(audio)

    chapters
    |> Enum.each(fn chapter ->
      create_chapter(audio, %{
        start: chapter.time,
        title: chapter.title,
        link: chapter.url,
        image: chapter.image
      })
    end)

    {:ok, audio}
  end
end
