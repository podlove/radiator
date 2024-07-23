defmodule Radiator.Outline.NodeRepoResult do
  @moduledoc """
    Generic result structure for node operations.
  """
  defstruct [
    :node,
    :old_prev_id,
    :old_next_id,
    :next_id,
    :children
  ]
end

defmodule Radiator.Outline do
  @moduledoc """
  The Outline context.
  """

  import Ecto.Query, warn: false

  alias Radiator.Outline.Node
  alias Radiator.Outline.NodeRepoResult
  alias Radiator.Outline.NodeRepository
  alias Radiator.Repo

  require Logger

  @doc """
  Returns a list of direct child nodes in correct order.
  """
  def order_child_nodes(%Node{} = node) do
    node
    |> get_all_child_nodes()
    |> order_sibling_nodes()
  end


  @doc """
  Orders a given list of nodes by their prev_id.
  """
  def order_sibling_nodes(nodes) do
    nodes
    |> Enum.map(fn node -> {node.prev_id, node} end)
    |> Map.new()
    |> order_nodes_by_index(nil, [])
  end


  @doc """
  Returns a list of all child nodes.
  """
  def list_nodes_by_episode_sorted(episode_id) do
    episode_id
    |> NodeRepository.list_nodes_by_episode()
    |> Enum.group_by(& &1.parent_id)
    |> Enum.map(fn {_parent_id, children} -> order_sibling_nodes(children) end)
    |> List.flatten()
  end

  defp order_nodes_by_index(index, prev_id, collection) do
    case index[prev_id] do
      %{uuid: uuid} = node -> order_nodes_by_index(index, uuid, [node | collection])
      _ -> Enum.reverse(collection)
    end
  end

  @doc """
  Inserts a node.

  ## Examples

      iex> insert_node(%{content: 'foo'})
      {:ok, %NodeRepoResult{}}

      iex> insert_node(%{content: value})
      {:error, :parent_and_prev_not_consistent}

  """
  # creates a node and inserts it into the outline tree
  # if a parent node is given, the new node will be inserted as a child of the parent node
  # if a previous node is given, the new node will be inserted after the previous node
  # if no parent is given, the new node will be inserted as a root node
  # if no previous node is given, the new node will be inserted as the first child of the parent node
  def insert_node(attrs) do
    Repo.transaction(fn ->
      prev_node_id = attrs["prev_id"]
      parent_node_id = attrs["parent_id"]
      episode_id = attrs["episode_id"]
      # find Node which has been previously connected to prev_node
      next_node =
        Node
        |> where(episode_id: ^episode_id)
        |> where_prev_node_equals(prev_node_id)
        |> where_parent_node_equals(parent_node_id)
        |> Repo.one()

      with parent_node <- NodeRepository.get_node_if(parent_node_id),
           prev_node <- NodeRepository.get_node_if(prev_node_id),
           true <- parent_and_prev_consistent?(parent_node, prev_node),
           {:ok, node} <- NodeRepository.create_node(attrs),
           {:ok, _node_to_move} <- move_node_if(next_node, parent_node_id, node.uuid),
           {:ok, node} <- move_node_if(node, parent_node_id, prev_node_id) do
        %NodeRepoResult{node: node, next_id: get_node_id(next_node)}
      else
        false ->
          Repo.rollback("Insert node failed. Parent and prev node are not consistent.")

        {:error, error} ->
          Logger.error("Insert node failed. #{inspect(error)}")
          Repo.rollback("Insert node failed. Unknown error")
      end
    end)
  end

  @doc """
  Moves a node to another parent.

  ## Examples

      iex> move_node(node_id, new_prev_id, new_parent_id)
      {:ok, %Node{}}
  """
  def move_node(node_id, new_prev_id, new_parent_id) do
    case NodeRepository.get_node(node_id) do
      nil ->
        {:error, :not_found}

      node ->
        prev_node = get_prev_node(node)
        parent_node = get_parent_node(node)

        if get_node_id(prev_node) != new_prev_id || get_node_id(parent_node) != new_parent_id do
          do_move_node(node, new_prev_id, new_parent_id, prev_node, parent_node)
        else
          {:ok, %NodeRepoResult{node: node}}
        end
    end
  end

  # low level function to move a node
  defp do_move_node(node, new_prev_id, new_parent_id, prev_node, parent_node) do
    node_repo_result = %NodeRepoResult{node: node}

    Repo.transaction(fn ->
      old_next_node =
        Node
        |> where_prev_node_equals(node.uuid)
        |> where_parent_node_equals(get_node_id(parent_node))
        |> Repo.one()

      new_next_node =
        Node
        |> where_prev_node_equals(new_prev_id)
        |> where_parent_node_equals(new_parent_id)
        |> Repo.one()

      {:ok, node} = move_node_if(node, new_parent_id, new_prev_id)

      {:ok, _old_next_node} =
        move_node_if(old_next_node, get_node_id(parent_node), get_node_id(prev_node))

      {:ok, _new_next_node} = move_node_if(new_next_node, new_parent_id, get_node_id(node))

      Map.merge(node_repo_result, %{
        node: node,
        old_next_id: get_node_id(old_next_node),
        old_prev_id: get_node_id(prev_node),
        next_id: get_node_id(new_next_node)
      })
    end)
  end

  @doc """
  Updates a nodes content.

  ## Examples

      iex> update_node_content(node_id, %{content: new_value})
      {:ok, %Node{}}

      iex> update_node_content(node_id, %{content: nil})
      {:error, %Ecto.Changeset{}}
  """
  def update_node_content(node_id, content) do
    case NodeRepository.get_node(node_id) do
      nil ->
        {:error, :not_found}

      node ->
        node
        |> Node.update_content_changeset(%{content: content})
        |> Repo.update()
    end
  end

  @doc """
  Removes a node from the tree and deletes it from the repository.
  Recursivly deletes all children if there are some.
  ## Examples

      iex> remove_node(node)
      {:ok, %Node{}}

      iex> remove_node(node)
      {:error, %Ecto.Changeset{}}

  """
  def remove_node(%Node{} = node) do
    next_node =
      Node
      |> where([n], n.prev_id == ^node.uuid)
      |> Repo.one()

    prev_node = get_prev_node(node)

    if next_node do
      next_node
      |> Node.move_node_changeset(%{prev_id: get_node_id(prev_node)})
      |> Repo.update()
    end

    # no tail recursion but we dont have too much levels in a tree
    node
    |> get_all_child_nodes()
    |> Enum.each(fn child_node ->
      remove_node(child_node)
    end)

    # finally delete the node itself from the database
    NodeRepository.delete_node(node)
  end

  @doc """
  Returns the previous node of a given node in the outline tree.
  Returns `nil` if prev_id of the node is nil.

  ## Examples
        iex> get_prev_node(%Node{prev_id: nil})
        nil

        iex> get_prev_node(%Node{prev_id: 42})
        %Node{uuid: 42}

  """
  def get_prev_node(node) when is_nil(node.prev_id), do: nil

  def get_prev_node(node) do
    Node
    |> where([n], n.uuid == ^node.prev_id)
    |> Repo.one()
  end

  @doc """
  Returns the parent node of a given node in the outline tree.
  Returns `nil` if parent_id of the node is nil.

  ## Examples
        iex> get_parent_node(%Node{parent_id: nil})
        nil

        iex> get_parent_node(%Node{parent_id: 42})
        %Node{uuid: 42}

  """
  def get_parent_node(node) when is_nil(node.parent_id), do: nil

  def get_parent_node(node) do
    Node
    |> where([n], n.uuid == ^node.parent_id)
    |> Repo.one()
  end

  @doc """
  Returns all child nodes of a given node.
  ## Examples
        iex> get_all_child_nodes(%Node{})
        [%Node{}, %Node{}]

  """
  def get_all_child_nodes(node) do
    Node
    |> where([n], n.parent_id == ^node.uuid)
    |> Repo.all()
  end

  @doc """
  Gets all nodes of an episode as a tree.
  Uses a Common Table Expression (CTE) to recursively query the database.
  Sets the level of each node in the tree. Level 0 are the root nodes (without a parent)
  Returns a list with all nodes of the episode sorted by the level.
  ## Examples

      iex> get_node_tree(123)
      [%Node{}, %Node{}, ..]

  SQL:
  WITH RECURSIVE node_tree AS (
        SELECT uuid, content, parent_id, prev_id, 0 AS level
        FROM outline_nodes
        WHERE episode_id = ?::integer and parent_id is NULL
     UNION ALL
        SELECT outline_nodes.uuid, outline_nodes.content, outline_nodes.parent_id, outline_nodes.prev_id, node_tree.level + 1
        FROM outline_nodes
           JOIN node_tree ON outline_nodes.parent_id = node_tree.uuid
  )
  SELECT * FROM node_tree;
  """
  def get_node_tree(episode_id) do
    node_tree_initial_query =
      Node
      |> where([n], is_nil(n.parent_id))
      |> where([n], n.episode_id == ^episode_id)
      |> select([n], %{
        uuid: n.uuid,
        content: n.content,
        parent_id: n.parent_id,
        prev_id: n.prev_id,
        level: 0
      })

    node_tree_recursion_query =
      from outline_node in "outline_nodes",
        join: node_tree in "node_tree",
        on: outline_node.parent_id == node_tree.uuid,
        select: [
          outline_node.uuid,
          outline_node.content,
          outline_node.parent_id,
          outline_node.prev_id,
          node_tree.level + 1
        ]

    node_tree_query =
      node_tree_initial_query
      |> union_all(^node_tree_recursion_query)

    tree =
      "node_tree"
      |> recursive_ctes(true)
      |> with_cte("node_tree", as: ^node_tree_query)
      |> select([n], %{
        uuid: n.uuid,
        content: n.content,
        parent_id: n.parent_id,
        prev_id: n.prev_id,
        level: n.level
      })
      |> Repo.all()
      |> Enum.map(fn %{
                       uuid: uuid,
                       content: content,
                       parent_id: parent_id,
                       prev_id: prev_id,
                       level: level
                     } ->
        %Node{
          uuid: binaray_uuid_to_ecto_uuid(uuid),
          content: content,
          parent_id: binaray_uuid_to_ecto_uuid(parent_id),
          prev_id: binaray_uuid_to_ecto_uuid(prev_id),
          level: level,
          episode_id: episode_id
        }
      end)

    {:ok, tree}
  end

  defp move_node_if(nil, _parent_node_id, _prev_node_id), do: {:ok, nil}

  defp move_node_if(node, parent_node_id, prev_node_id) do
    node
    |> Node.move_node_changeset(%{
      parent_id: parent_node_id,
      prev_id: prev_node_id
    })
    |> Repo.update()
  end

  defp parent_and_prev_consistent?(_, nil), do: true
  defp parent_and_prev_consistent?(nil, _), do: true

  defp parent_and_prev_consistent?(parent, prev) do
    parent.uuid == prev.parent_id
  end

  defp where_prev_node_equals(node, nil), do: where(node, [n], is_nil(n.prev_id))
  defp where_prev_node_equals(node, prev_id), do: where(node, [n], n.prev_id == ^prev_id)

  defp where_parent_node_equals(node, nil), do: where(node, [n], is_nil(n.parent_id))
  defp where_parent_node_equals(node, parent_id), do: where(node, [n], n.parent_id == ^parent_id)

  defp get_node_id(nil), do: nil

  defp get_node_id(%Node{} = node) do
    node.uuid
  end

  defp binaray_uuid_to_ecto_uuid(nil), do: nil

  defp binaray_uuid_to_ecto_uuid(uuid) do
    Ecto.UUID.load!(uuid)
  end
end
