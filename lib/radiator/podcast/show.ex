defmodule Radiator.Podcast.Show do
  @moduledoc """
    Represents the show model.
    A show can have many episodes.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Radiator.Podcast.{Episode, Network}

  schema "shows" do
    field :title, :string
    field :description, :string

    belongs_to :network, Network

    has_many(:episodes, Episode)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(show, attrs) do
    show
    |> cast(attrs, [:title, :description, :network_id])
    |> validate_required([:title])
  end
end
