defmodule Radiator.Outline do
  @moduledoc """
  The Outline context.
  """
  import Ecto.Query, warn: false

  alias Phoenix.PubSub
  alias Radiator.Outline.Node
  alias Radiator.Repo

  @topic "outline"

  @doc """
  Returns the list of nodes.

  ## Examples

      iex> list_nodes()
      [%Node{}, ...]

  """
  def list_nodes do
    Node
    |> Repo.all()
  end

  @doc """
  Gets a single node.

  Raises `Ecto.NoResultsError` if the Node does not exist.

  ## Examples

      iex> get_node!(123)
      %Node{}

      iex> get_node!(456)
      ** (Ecto.NoResultsError)

  """
  def get_node!(id) do
    Node
    |> Repo.get!(id)
  end

  @doc """
  Gets a single node.

  Returns `nil` if the Node does not exist.

  ## Examples

      iex> get_node(123)
      %Node{}

      iex> get_node(456)
      nil

  """
  def get_node(id) do
    Node
    |> Repo.get(id)
  end

  @doc """
  Gets all nodes of an episode as a tree.

  ## Examples

      iex> get_node_tree(123)
      [%Node{}, %Node{}, ..]
  """
  #  episode_id = 2
  #  Radiator.Outline.get_node_tree(episode_id)
  def get_node_tree(episode_id) do

    node_tree_initial_query =
      Node
      |> where([n], is_nil(n.parent_id))
      |> where([n], n.episode_id == ^episode_id)
      |> select([n], %{uuid: n.uuid, content: n.content, parent_id: n.parent_id, prev_id: n.prev_id, level: 0})

    node_tree_recursion_query = from outline_node in "outline_nodes",
      join: node_tree in "node_tree", on: outline_node.parent_id == node_tree.uuid,
      select: [outline_node.uuid, outline_node.content, outline_node.parent_id, outline_node.prev_id, node_tree.level + 1]

    node_tree_query =
      node_tree_initial_query
      |> union_all(^node_tree_recursion_query)

    tree =
      "node_tree"
      |> recursive_ctes(true)
      |> with_cte("node_tree", as: ^node_tree_query)
      |> select([n], %{uuid: n.uuid, content: n.content, parent_id: n.parent_id, prev_id: n.prev_id, level: n.level})
      |> Repo.all()
      |> Enum.map(fn %{uuid: uuid, content: content, parent_id: parent_id, prev_id: prev_id, level: level} ->
        %Node{uuid: binaray_uuid_to_ecto_uuid(uuid), content: content, parent_id:  binaray_uuid_to_ecto_uuid(parent_id), prev_id:  binaray_uuid_to_ecto_uuid(prev_id), level: level}
      end)
    {:ok, tree}
  end

  defp binaray_uuid_to_ecto_uuid(nil), do: nil
  defp binaray_uuid_to_ecto_uuid(uuid) do
    Ecto.UUID.load!(uuid)
  end



  @doc """
  Creates a node.

  ## Examples

      iex> create_node(%{field: value})
      {:ok, %Node{}}

      iex> create_node(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_node(attrs \\ %{}) do
    %Node{}
    |> Node.insert_changeset(attrs)
    |> Repo.insert()
    |> broadcast_node_action(:insert)
  end

  def create_node(attrs, %{id: id}) do
    %Node{creator_id: id}
    |> Node.insert_changeset(attrs)
    |> Repo.insert()
    |> broadcast_node_action(:insert)
  end

  @doc """
  Updates a nodes content.

  ## Examples

      iex> update_node_content(node, %{content: new_value})
      {:ok, %Node{}}

      iex> update_node_content(node, %{content: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_node_content(%Node{} = node, attrs) do
    node
    |> Node.update_content_changeset(attrs)
    |> Repo.update()
    |> broadcast_node_action(:update)
  end

  @doc """
  Moves a nodes to another parent.

  ## Examples

      iex> move_node(node, %Node{uuid: new_parent_id})
      {:ok, %Node{}}

      iex> move_node(node, nil)
      {:error, %Ecto.Changeset{}}

  """
  def move_node(%Node{} = node, %Node{} = parent_node) do
    node
    |> Node.move_changeset(parent_node)
    |> Repo.update()
    |> broadcast_node_action(:update)
  end

  @doc """
  Deletes a node.

  ## Examples

      iex> delete_node(node)
      {:ok, %Node{}}

      iex> delete_node(node)
      {:error, %Ecto.Changeset{}}

  """
  def delete_node(%Node{} = node) do
    node
    |> Repo.delete()
    |> broadcast_node_action(:delete)
  end

  defp broadcast_node_action({:ok, node}, action) do
    PubSub.broadcast(Radiator.PubSub, @topic, {action, node})
    {:ok, node}
  end

  defp broadcast_node_action({:error, error}, _action), do: {:error, error}
end
