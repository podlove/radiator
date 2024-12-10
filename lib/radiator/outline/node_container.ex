defmodule Radiator.Outline.NodeContainer do
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Outline.Node

  schema "outline_node_containers" do
    has_many :outline_nodes, Node

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(node_container, attrs) do
    node_container
    |> cast(attrs, [])
    |> validate_required([])
  end
end
