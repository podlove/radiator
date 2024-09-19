defmodule Radiator.Web.Url do
  @moduledoc """
  An extracted URL which always related to a node.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "urls" do
    field :url, :string
    field :start_bytes, :integer
    field :size_bytes, :integer

    belongs_to :node, Radiator.Outline.Node, type: :binary_id, references: :uuid
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(url, attrs) do
    url
    |> cast(attrs, [:url, :start_bytes, :size_bytes, :node_id])
    |> validate_required([:url, :start_bytes, :size_bytes, :node_id])
  end
end
