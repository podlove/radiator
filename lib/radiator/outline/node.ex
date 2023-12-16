defmodule Radiator.Outline.Node do
  @moduledoc """
  The node model which represents a single node in the outline.
  Currenty there is no concept of a tree
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Radiator.Podcast.Episode

  @derive {Jason.Encoder, only: [:uuid, :content, :creator_id, :parent_id, :prev_id]}

  @primary_key {:uuid, :binary_id, autogenerate: true}
  schema "outline_nodes" do
    field :content, :string
    field :creator_id, :integer
    field :parent_id, Ecto.UUID
    field :prev_id, Ecto.UUID

    belongs_to :episode, Episode

    timestamps(type: :utc_datetime)
  end

  @required_fields [
    :content
  ]

  @optional_fields [
    :creator_id,
    :parent_id,
    :prev_id,
    :episode_id # FIXME: should be required
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
