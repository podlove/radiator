defmodule Radiator.Podcast.Episode do
  @moduledoc """
    Represents the Episode model.
    Episodes are numbered inside a show.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Podcast.Show
  @slug_max_length 500

  schema "episodes" do
    field :title, :string
    field :number, :integer
    field :publish_date, :date
    field :slug, :string
    field :is_deleted, :boolean, default: false
    field :deleted_at, :utc_datetime
    field :root_node_id, :binary_id, virtual: true
    field :inbox_node_id, :binary_id, virtual: true

    belongs_to :show, Show

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(episode, attrs) do
    episode
    |> cast(attrs, [:title, :show_id, :number, :publish_date, :slug, :is_deleted, :deleted_at])
    |> validate_required([:title, :show_id, :number])
    |> validate_length(:title, min: 3)
    |> maybe_update_slug()
    |> validate_deleted_at()
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

  defp validate_deleted_at(changeset) do
    # Check if the is_deleted has changed
    case get_change(changeset, :is_deleted) do
      true ->
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        put_change(changeset, :deleted_at, now)

      false ->
        put_change(changeset, :deleted_at, nil)

      nil ->
        changeset
    end
  end
end
