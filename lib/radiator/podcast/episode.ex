defmodule Radiator.Podcast.Episode do
  @moduledoc """
    Represents the Episode model.
    TODO: Episodes should be numbered and ordered inside a show.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Podcast.Show

  schema "episodes" do
    field :title, :string
    field :number, :integer
    belongs_to :show, Show
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(episode, attrs) do
    episode
    |> cast(attrs, [:title, :show_id, :number])
    |> validate_required([:title, :show_id, :number])
  end
end
