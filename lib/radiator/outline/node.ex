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
    |> cast(attributes, [:content, :episode_id, :creator_id, :parent_id, :prev_id])
    |> update_change(:content, &trim/1)
    |> validate_required([:content, :episode_id])
  end

  @doc """
  Changeset for moving a node
  Only the parent_id is allowed and expected to be changed
  """
  def move_changeset(node, new_parent_node) do
    node
    |> cast(%{parent_id: new_parent_node.uuid}, [:parent_id])
    |> validate_parent(new_parent_node)
  end

  @doc """
  Changeset for updating the content of a node
  """
  def update_content_changeset(node, attrs) do
    node
    |> cast(attrs, [:content])
    |> update_change(:content, &trim/1)
    |> validate_required([:content])
  end

  defp trim(content) when is_binary(content), do: String.trim(content)
  defp trim(content), do: content

  defp validate_parent(changeset, nil), do: add_error(changeset, :parent_id, "must not be nil")

  defp validate_parent(changeset, parent_node) do
    cond do
      parent_node.uuid == changeset.data.uuid ->
        add_error(changeset, :parent_id, "must not be the same as the node itself")

      parent_node.parent_id == changeset.data.uuid ->
        add_error(changeset, :parent_id, "node is already parent of the parent node")

      parent_node.episode_id != changeset.data.episode_id ->
        add_error(changeset, :parent_id, "nodes must be in the same episode")

      true ->
        changeset
    end
  end
end
