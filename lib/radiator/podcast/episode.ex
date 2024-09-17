defmodule Radiator.Podcast.Episode do
  @moduledoc """
    Represents the Episode model.
    Episodes are numbered inside a show.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Podcast.Show
  @slug_max_length 50

  schema "episodes" do
    field :title, :string
    field :number, :integer
    field :publish_date, :date
    field :slug, :string

    belongs_to :show, Show

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(episode, attrs) do
    episode
    |> cast(attrs, [:title, :show_id, :number, :publish_date, :slug])
    |> validate_required([:title, :show_id, :number])
    |> maybe_update_slug()
    |> validate_slug()
  end

  defp maybe_update_slug(changeset) do
    # Check if the title has changed
    case get_change(changeset, :title) do
      nil ->
        # No title change, keep slug as is
        changeset

      new_title ->
        new_slug = Slug.slugify(new_title, truncate: @slug_max_length)

        changeset
        |> put_change(:slug, new_slug)
    end
  end

  defp validate_slug(changeset) do
    changeset
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "can only contain lowercase letters, numbers, and dashes"
    )
    |> validate_length(:slug, min: 3, max: @slug_max_length)
  end
end
