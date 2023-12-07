defmodule Radiator.Outline.Node do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uuid, :binary_id, autogenerate: true}
  schema "outline_nodes" do
    field :content, :string
    field :creator_id, :integer
    field :parent_id, Ecto.UUID
    field :prev_id, Ecto.UUID

    timestamps(type: :utc_datetime)
  end

  @required_fields [
    :content
  ]

  @optional_fields [
    :creator_id,
    :parent_id,
    :prev_id
  ]

  @all_fields @optional_fields ++ @required_fields

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, @all_fields)
    |> update_change(:content, &trim/1)
    |> validate_required(@required_fields)
  end

  defp trim(content) when is_binary(content), do: String.trim(content)
  defp trim(content), do: content
end
