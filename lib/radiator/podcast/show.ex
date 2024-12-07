defmodule Radiator.Podcast.Show do
  @moduledoc """
    Represents the show model.
    A show can have many episodes.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Radiator.Accounts.User
  alias Radiator.Outline.Node
  alias Radiator.Podcast.{Episode, Network}

  schema "shows" do
    field :title, :string
    field :description, :string

    belongs_to :network, Network
    belongs_to :global_root, Node, type: :binary_id, references: :uuid
    belongs_to :global_inbox, Node, type: :binary_id, references: :uuid
    has_many(:episodes, Episode)
    has_many(:outline_nodes, Node, on_delete: :delete_all)
    many_to_many(:hosts, User, join_through: "show_hosts")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(show, attrs) do
    show
    |> cast(attrs, [:title, :description, :network_id])
    |> validate_required([:title])
  end

  @doc """
  changeset for updating the show's root and inbox nodes
  """
  def changeset_tree(show, attrs) do
    show
    |> cast(attrs, [:global_root_id, :global_inbox_id])
    |> validate_required([:global_root_id, :global_inbox_id])
  end
end
