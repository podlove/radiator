defmodule Radiator.EpisodeMeta do
  @moduledoc """
  The Episode Metadata context.
  """

  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Directory.Episode
  alias Radiator.EpisodeMeta.Chapter

  def list_chapters(%Episode{} = episode) do
    from(
      c in Chapter,
      where: c.episode_id == ^episode.id,
      order_by: [asc: c.time]
    )
    |> Repo.all()
  end

  def create_chapter(%Episode{} = episode, attrs) do
    %Chapter{}
    |> Chapter.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:episode, episode)
    |> Repo.insert()
  end

  def set_chapters(%Episode{} = episode, input, type)
      when is_binary(input) and type in [:psc, :json, :mp4chaps] do
    chapters = Chapters.decode(input, type)

    # transaction:
    # - delete existing chapters
    # - insert all new chapters

    chapters
    |> Enum.each(fn chapter ->
      create_chapter(episode, %{
        time: chapter.time,
        title: chapter.title,
        url: chapter.url,
        image: chapter.image
      })
    end)

    {:ok, episode}
  end
end
