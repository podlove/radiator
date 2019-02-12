defmodule Radiator.Directory.Podcast do
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Directory.Episode

  schema "podcasts" do
    field :author, :string
    field :description, :string
    field :image, :string
    field :language, :string
    field :last_built_at, :utc_datetime
    field :owner_email, :string
    field :owner_name, :string
    field :published_at, :utc_datetime
    field :subtitle, :string
    field :title, :string

    has_many(:episodes, Episode)

    timestamps()
  end

  @doc false
  def changeset(podcast, attrs) do
    podcast
    |> cast(attrs, [
      :title,
      :subtitle,
      :description,
      :image,
      :author,
      :owner_name,
      :owner_email,
      :language,
      :published_at,
      :last_built_at
    ])
    |> validate_required([:title])
  end
end
