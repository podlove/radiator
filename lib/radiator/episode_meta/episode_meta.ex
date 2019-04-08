defmodule Radiator.EpisodeMeta do
  @moduledoc """
  The Episode Metadata context.
  """

  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Directory.Episode
  alias Radiator.EpisodeMeta.Chapter

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

  def list_chapters(%Episode{} = episode) do
    from(
      c in Chapter,
      where: c.episode_id == ^episode.id,
      order_by: [asc: c.start]
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
        start: chapter.time,
        title: chapter.title,
        link: chapter.url,
        image: chapter.image
      })
    end)

    {:ok, episode}
  end
end
