defmodule Radiator.EpisodeMeta.Chapter do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query, warn: false

  alias Radiator.Directory.Episode

  schema "chapters" do
    field :time, :integer
    field :title, :string
    field :url, :string
    field :image, :string

    belongs_to :episode, Episode
  end

  @doc false
  def changeset(chapter, attrs) do
    chapter
    |> cast(attrs, [
      :time,
      :title,
      :url,
      :image
    ])
  end
end
