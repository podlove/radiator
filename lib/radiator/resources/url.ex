defmodule Radiator.Resources.Url do
  @moduledoc """
  An extracted URL which always related to a node.
  """
  use Ecto.Schema
  import Ecto.Changeset

  defmodule Data do
    @moduledoc false
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

    embeds_one :data, Data

    belongs_to :node, Radiator.Outline.Node, type: :binary_id, references: :uuid
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(url, attrs) do
    url
    |> cast(attrs, [:url, :start_bytes, :size_bytes, :node_id])
    |> validate_required([:url, :start_bytes, :size_bytes, :node_id])
    |> cast_embed(:data, with: &Data.changeset/2)
  end
end
