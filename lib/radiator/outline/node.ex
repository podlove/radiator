defmodule Radiator.Outline.Node do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uuid, :binary_id, autogenerate: true}
  schema "outline_nodes" do
    field :content, :string

    timestamps(type: :utc_datetime)
  end

  @fields [
    :content
  ]

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
