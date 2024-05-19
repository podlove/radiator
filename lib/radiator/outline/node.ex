defmodule Radiator.Outline.Node do
  @moduledoc """
  The node model represents a single node in the outline.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Radiator.Podcast.Episode

  @derive {Jason.Encoder, only: [:uuid, :content, :creator_id, :parent_id, :prev_id]}

  @primary_key {:uuid, :binary_id, autogenerate: false}
  schema "outline_nodes" do
    field :content, :string
    field :creator_id, :integer
    field :parent_id, Ecto.UUID
    field :prev_id, Ecto.UUID
    field :level, :integer, virtual: true

    belongs_to :episode, Episode

    timestamps(type: :utc_datetime)
  end

  @doc """
  A changeset for inserting a new node
  Work in progress. Since we currently ignore the tree structure, there is
  no concept for a root node.
  Also questionable wether a node really needs a content from beginning. So probably a root
  doesnt have a content
  Another issue might be we need to create the uuid upfront and pass it here
  """
  def insert_changeset(node, attributes) do
    node
    |> cast(attributes, [:uuid, :content, :episode_id, :creator_id, :parent_id, :prev_id])
    |> put_uuid()
    |> update_change(:content, &trim/1)
    |> validate_required([:episode_id])
    |> validate_format(:uuid, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
    |> unique_constraint(:uuid, name: "outline_nodes_pkey")
  end

  @doc """
  Changeset for updating the content of a node
  """
  def update_content_changeset(node, attrs) do
    node
    |> cast(attrs, [:content])
    |> update_change(:content, &trim/1)
  end

  def move_node_changeset(node, attrs) do
    node
    |> cast(attrs, [:parent_id, :prev_id])
  end

  defp trim(content) when is_binary(content), do: String.trim(content)
  defp trim(content), do: content

  defp put_uuid(%Ecto.Changeset{valid?: true} = changeset) do
    if changed?(changeset, :uuid) do
      changeset
    else
      put_change(changeset, :uuid, Ecto.UUID.generate())
    end
  end

  defp put_uuid(changeset), do: changeset
end
