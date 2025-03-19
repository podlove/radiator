defmodule Radiator.Podcast.Show do
  @moduledoc """
    Represents the show model.
    A show can have many episodes.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Radiator.Accounts.User
  alias Radiator.Outline.NodeContainer
  alias Radiator.Podcast.{Episode, Network}

  schema "shows" do
    field :title, :string
    field :description, :string

    belongs_to :network, Network
    belongs_to :inbox_node_container, NodeContainer

    has_many(:episodes, Episode)
    many_to_many(:hosts, User, join_through: "show_hosts")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(show, attrs) do
    show
    |> cast(attrs, [:title, :description, :network_id])
    |> validate_required([:title])
  end
end
