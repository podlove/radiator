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
    |> update_change(:content, &trim/1)
    |> validate_required(@fields)
  end

  defp trim(content) when is_binary(content), do: String.trim(content)
  defp trim(content), do: content
end
