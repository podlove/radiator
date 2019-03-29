defmodule Radiator.Directory.Episode.Chapter do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query, warn: false

  alias Radiator.Directory.Episode

  schema "chapters" do
    field :time, :integer
    field :title, :string
    field :link_url, :string
    field :image_url, :string

    belongs_to :episode, Episode
  end

  @doc false
  def changeset(chapter, attrs) do
    chapter
    |> cast(attrs, [
      :time,
      :title,
      :link_url,
      :image_url
    ])
  end
end
