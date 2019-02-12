defmodule Radiator.Podcast.Show do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shows" do
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

    timestamps()
  end

  @doc false
  def changeset(show, attrs) do
    show
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
    |> validate_required([])
  end
end
