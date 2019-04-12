defmodule Radiator.EpisodeMeta.Chapter do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query, warn: false

  alias Radiator.Directory.Episode

  schema "chapters" do
    field :start, :integer
    field :title, :string
    field :link, :string
    field :image, :string

    belongs_to :episode, Episode
  end

  @doc false
  def changeset(chapter, attrs) do
    chapter
    |> cast(attrs, [
      :start,
      :title,
      :link,
      :image
    ])
  end
end
