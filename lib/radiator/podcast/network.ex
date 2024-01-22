defmodule Radiator.Podcast.Network do
  @moduledoc """
    Represents the network model.
    A network can host many shows.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Podcast.Show

  schema "networks" do
    field :title, :string

    has_many(:shows, Show)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(network, attrs) do
    network
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
