defmodule Radiator.Resources.Url do
  @moduledoc """
  An extracted URL which always related to a node.
  """
  use Ecto.Schema
  import Ecto.Changeset

  defmodule MetaData do
    @moduledoc """
    Meta data for a URL depending on the analyzers.
    Under construction!
    A Youtube URL will have different meta data than a normal web page for instance
    """
    use Ecto.Schema

    embedded_schema do
      field :title, :string
    end

    def changeset(data, attrs) do
      data
      |> cast(attrs, [:title])
    end
  end

  schema "urls" do
    field :url, :string
    field :start_bytes, :integer
    field :size_bytes, :integer

    embeds_one :meta_data, MetaData

    belongs_to :node, Radiator.Outline.Node, type: :binary_id, references: :uuid
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(url, attrs) do
    url
    |> cast(attrs, [:url, :start_bytes, :size_bytes, :node_id])
    |> validate_required([:url, :start_bytes, :size_bytes, :node_id])
    |> cast_embed(:meta_data, with: &MetaData.changeset/2)
  end
end
