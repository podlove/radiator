defmodule Radiator.Outline.NodeRepoResult do
  @moduledoc """
    Generic result structure for node operations.
  """
  defstruct [
    :node,
    :old_prev,
    :old_next,
    :next,
    :children,
    :episode_id
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
  alias Radiator.Outline.Validations, as: NodeValidator
  alias Radiator.Repo

  require Logger

  @doc """
  Returns a list of direct child nodes in correct order.
  """
  def order_child_nodes(nil), do: []

  def order_child_nodes(%Node{} = node) do
    node
    |> get_all_siblings()
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
      prev_id = attrs["prev_id"]
      parent_id = attrs["parent_id"]
      episode_id = attrs["episode_id"]

      prev_node = NodeRepository.get_node_if(prev_id)
      parent_node = find_parent_node(prev_node, parent_id)

      # find Node which has been previously connected to prev_node
      next_node = get_next_node(episode_id, prev_id, get_node_id(parent_node))

      with true <- parent_and_prev_consistent?(parent_node, prev_node),
           true <- episode_valid?(episode_id, parent_node, prev_node),
           {:ok, node} <- NodeRepository.create_node(set_parent_id_if(attrs, parent_node)),
           {:ok, _node_to_move} <- move_node_if(next_node, get_node_id(parent_node), node.uuid) do
        %NodeRepoResult{node: node, next: get_node_result_info(next_node), episode_id: episode_id}
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
  Intends a node given by its id (by using the tab key).

  ## Examples

      iex> indent_node("074b755d-d095-4b9c-8445-ef1f7ea76d54")
      {:ok, %NodeRepoResult{}}

      iex> indent_node("0000000-1111-2222-3333-44444444")
      {:error, :not_found}

  """
  def indent_node(node_id) do
    Repo.transaction(fn ->
      case NodeRepository.get_node(node_id) do
        nil ->
          {:error, :not_found}

        node ->
          prev_node = get_prev_node(node)
          do_indent_node(node, prev_node)
      end
    end)
    |> unwrap_transaction_result
  end

  @doc """
  Outdents a node given by its id (by using the shift-tab keys).

  ## Examples

      iex> outdent_node("074b755d-d095-4b9c-8445-ef1f7ea76d54")
      {:ok, %NodeRepoResult{}}

      iex> outdent_node("0000000-1111-2222-3333-44444444")
      {:error, :not_found}

  """
  def outdent_node(node_id) do
    Repo.transaction(fn ->
      case NodeRepository.get_node(node_id) do
        nil ->
          {:error, :not_found}

        node ->
          parent_node = get_parent_node(node)
          do_outdent_node(node, parent_node)
      end
    end)
    |> unwrap_transaction_result
  end

  @doc """
  Moves a node up in the outline tree. Only works if the node
  is not the first child of its parent meaning there must be a
  previous node. In that case the two nodes will switch places.
  ## Examples

      iex> move_up("074b755d-d095-4b9c-8445-ef1f7ea76d54")
      {:ok, %NodeRepoResult{}}

      iex> move_up("0000000-1111-2222-3333-44444444")
      {:error, :not_found}

  """
  def move_up(node_id) do
    Repo.transaction(fn ->
      case NodeRepository.get_node(node_id) do
        nil ->
          {:error, :not_found}

        node ->
          prev_node = get_prev_node(node)
          do_move_up(node, prev_node)
      end
    end)
    |> unwrap_transaction_result
  end

  @doc """
  Moves a node down in the outline tree. Only works if the node
  is not the last child of its parent meaning there must be a next node.
  In that case the two nodes will switch places.
  ## Examples

      iex> move_down("074b755d-d095-4b9c-8445-ef1f7ea76d54")
      {:ok, %NodeRepoResult{}}

      iex> move_down("0000000-1111-2222-3333-44444444")
      {:error, :not_found}
  """
  def move_down(node_id) do
    Repo.transaction(fn ->
      case NodeRepository.get_node(node_id) do
        nil ->
          {:error, :not_found}

        node ->
          next_node = get_next_node(node)
          do_move_down(node, next_node)
      end
    end)
    |> unwrap_transaction_result
  end

  @doc """
  Moves a node to another parent.

  ## Examples

      iex> move_node(node_id, new_prev_id, new_parent_id)
      {:ok, %Node{}}
  """
  def move_node(node_id, prev_id: node_id, parent_id: _new_parent_id) do
    {:error, :self_link}
  end

  def move_node(node_id, prev_id: _new_prev_id, parent_id: node_id) do
    {:error, :circle_link}
  end

  def move_node(_node_id, prev_id: other_id, parent_id: other_id) when not is_nil(other_id) do
    {:error, :parent_and_prev_not_consistent}
  end

  def move_node(node_id, prev_id: new_prev_id, parent_id: new_parent_id) do
    case NodeRepository.get_node(node_id) do
      nil ->
        {:error, :not_found}

      node ->
        parent_node = get_parent_node(node)

        case NodeValidator.validate_consistency_for_move(
               node,
               new_prev_id,
               new_parent_id,
               parent_node
             ) do
          {:error, error} ->
            {:error, error}

          {:ok, node} ->
            prev_node = get_prev_node(node)
            do_move_node(node, new_prev_id, new_parent_id, prev_node, parent_node)
        end
    end
  end

  def move_node(node_id, parent_id: parent_id, prev_id: new_prev_id),
    do: move_node(node_id, prev_id: new_prev_id, parent_id: parent_id)

  def move_node(node_id, prev_id: new_prev_id) do
    parent_id =
      new_prev_id
      |> NodeRepository.get_node_if()
      |> get_parent_node
      |> get_node_id

    move_node(node_id, prev_id: new_prev_id, parent_id: parent_id)
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
      { %NodeRepoResult{} }

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
    all_children = node |> get_all_siblings()

    recursive_deleted_children =
      all_children
      |> Enum.map(fn child_node ->
        %NodeRepoResult{children: children} = remove_node(child_node)
        children
      end)
      |> List.flatten()

    # finally delete the node itself from the database
    {:ok, deleted_node} = NodeRepository.delete_node(node)

    %NodeRepoResult{
      node: deleted_node,
      next: get_node_result_info(next_node),
      children: all_children ++ recursive_deleted_children,
      episode_id: node.episode_id
    }
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
  def get_prev_node(nil), do: nil
  def get_prev_node(%Node{prev_id: nil}), do: nil

  def get_prev_node(%Node{} = node) do
    Node
    |> where([n], n.uuid == ^node.prev_id)
    |> Repo.one()
  end

  def get_next_node(%Node{episode_id: episode_id, uuid: node_id, parent_id: parent_id}) do
    get_next_node(episode_id, node_id, parent_id)
  end

  def get_next_node(episode_id, node_id, parent_id) do
    Node
    |> where(episode_id: ^episode_id)
    |> where_prev_node_equals(node_id)
    |> where_parent_node_equals(parent_id)
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

        iex> get_parent_node(nil)
        nil

  """
  def get_parent_node(nil), do: nil
  def get_parent_node(node) when is_nil(node.parent_id), do: nil

  def get_parent_node(node) do
    Node
    |> where([n], n.uuid == ^node.parent_id)
    |> Repo.one()
  end

  @doc """
  Returns all direct child nodes of a given node.
  ## Examples
        iex> get_all_siblings(%Node{})
        [%Node{}, %Node{}]

  """
  def get_all_siblings(nil) do
    Node
    |> where([n], is_nil(n.parent_id))
    |> Repo.all()
  end

  def get_all_siblings(node) do
    Node
    |> where([n], n.parent_id == ^node.uuid)
    |> Repo.all()
  end

  @doc """
  get all children of a node. there is no limit of levels.
  It basically calls `get_all_siblings` recursively and flattens the result.
  ## Examples
        iex> get_all_children(%Node{})
        [%Node{}, %Node{}]
  """
  def get_all_children(node) do
    siblings = node |> get_all_siblings()

    children =
      siblings
      |> Enum.map(&get_all_children/1)
      |> List.flatten()
      |> Enum.reject(&is_nil/1)

    siblings ++ children
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

  def get_node_id(nil), do: nil
  def get_node_id(%Node{} = node), do: node.uuid

  defp episode_valid?(episode_id, %Node{episode_id: episode_id}, %Node{episode_id: episode_id}),
    do: true

  defp episode_valid?(episode_id, %Node{episode_id: episode_id}, nil), do: true
  defp episode_valid?(episode_id, nil, %Node{episode_id: episode_id}), do: true
  defp episode_valid?(_episode_id, nil, nil), do: true
  defp episode_valid?(_episode_id, _parent_node, _prev_node), do: false

  defp set_parent_id_if(attrs, nil), do: attrs
  defp set_parent_id_if(attrs, %Node{uuid: uuid}), do: Map.put_new(attrs, "parent_id", uuid)

  defp find_parent_node(%Node{parent_id: parent_id}, nil) do
    NodeRepository.get_node_if(parent_id)
  end

  defp find_parent_node(_, parent_id) do
    NodeRepository.get_node_if(parent_id)
  end

  defp move_node_if(nil, _parent_node_id, _prev_node_id), do: {:ok, nil}

  defp move_node_if(node, parent_id, prev_id) do
    node
    |> Node.move_node_changeset(%{
      parent_id: parent_id,
      prev_id: prev_id
    })
    |> Repo.update()
  end

  # low level function to move a node
  defp do_move_node(node, new_prev_id, new_parent_id, prev_node, parent_node) do
    node_repo_result = %NodeRepoResult{
      node: get_node_result_info(node),
      episode_id: node.episode_id
    }

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

      if !is_nil(old_next_node) do
        {:ok, _old_next_node} =
          move_node_if(old_next_node, old_next_node.parent_id, get_node_id(prev_node))
      end

      {:ok, _new_next_node} = move_node_if(new_next_node, new_parent_id, get_node_id(node))

      Map.merge(node_repo_result, %{
        node: get_node_result_info(node),
        old_next: get_node_result_info(old_next_node),
        old_prev: get_node_result_info(prev_node),
        next: get_node_result_info(new_next_node)
      })
    end)
  end

  defp do_indent_node(_node, nil), do: {:error, :no_prev_node}

  defp do_indent_node(node, prev_node) do
    new_previous_id =
      prev_node
      |> order_child_nodes()
      |> List.last()
      |> get_node_id()

    move_node(node.uuid, prev_id: new_previous_id, parent_id: prev_node.uuid)
  end

  defp do_outdent_node(_node, nil), do: {:error, :no_parent_node}

  defp do_outdent_node(node, parent_node) do
    new_children =
      parent_node
      |> order_child_nodes()
      |> next_nodes(node)

    last_of_old_children =
      node
      |> order_child_nodes()
      |> List.last()

    {:ok, main_move_result} =
      move_node(node.uuid, prev_id: parent_node.uuid, parent_id: parent_node.parent_id)

    # new children are the possible new child elements of the node
    # if the node already had children the new children are appended to the list of existing children
    _t =
      Enum.reduce(new_children, get_node_id(last_of_old_children), fn n, prev_id ->
        move_node_if(n, node.uuid, prev_id)
        n.uuid
      end)

    {:ok, Map.put(main_move_result, :children, new_children)}
  end

  defp do_move_up(%Node{}, nil), do: {:error, :no_previous_node}

  defp do_move_up(
         %Node{episode_id: episode_id, parent_id: parent_id} = node,
         %Node{} = prev_node
       ) do
    next_node = get_next_node(episode_id, node.uuid, parent_id)

    move_node_if(node, parent_id, prev_node.prev_id)
    move_node_if(prev_node, parent_id, node.uuid)
    move_node_if(next_node, parent_id, prev_node.uuid)

    %NodeRepoResult{
      node: get_node_result_info(node),
      episode_id: episode_id,
      old_prev: get_node_result_info(prev_node),
      old_next: get_node_result_info(next_node)
    }
  end

  defp do_move_down(%Node{}, nil), do: {:error, :no_next_node}

  defp do_move_down(
         %Node{episode_id: episode_id, parent_id: parent_id} = node,
         %Node{} = next_node
       ) do
    new_next_node = get_next_node(next_node)

    move_node_if(next_node, parent_id, node.prev_id)
    move_node_if(node, parent_id, next_node.uuid)
    move_node_if(new_next_node, parent_id, node.uuid)

    %NodeRepoResult{
      node: get_node_result_info(node),
      episode_id: episode_id,
      old_next: get_node_result_info(next_node),
      next: get_node_result_info(new_next_node)
    }
  end

  # given a list of nodes in one level, return all the nodes that are after a give
  defp next_nodes([], _node), do: []
  defp next_nodes([%{prev_id: uuid} | _tail] = children, %{uuid: uuid}), do: children

  defp next_nodes([_head | tail_children], node),
    do: next_nodes(tail_children, node)

  defp parent_and_prev_consistent?(_, nil), do: true
  defp parent_and_prev_consistent?(nil, _), do: true

  defp parent_and_prev_consistent?(parent, prev) do
    parent.uuid == prev.parent_id
  end

  defp where_prev_node_equals(node, nil), do: where(node, [n], is_nil(n.prev_id))
  defp where_prev_node_equals(node, prev_id), do: where(node, [n], n.prev_id == ^prev_id)

  defp where_parent_node_equals(node, nil), do: where(node, [n], is_nil(n.parent_id))
  defp where_parent_node_equals(node, parent_id), do: where(node, [n], n.parent_id == ^parent_id)

  def get_node_result_info(nil), do: nil

  def get_node_result_info(%Node{uuid: uuid, prev_id: prev_id, parent_id: parent_id}),
    do: %Node{uuid: uuid, prev_id: prev_id, parent_id: parent_id}

  defp order_nodes_by_index(index, prev_id, collection) do
    case index[prev_id] do
      %{uuid: uuid} = node -> order_nodes_by_index(index, uuid, [node | collection])
      _ -> Enum.reverse(collection)
    end
  end

  defp unwrap_transaction_result({:ok, {:error, error}}) do
    {:error, error}
  end

  defp unwrap_transaction_result({:ok, {:ok, node_result}}) do
    {:ok, node_result}
  end

  defp unwrap_transaction_result({:error, error}) do
    {:error, error}
  end

  defp unwrap_transaction_result(result), do: result

  defp binaray_uuid_to_ecto_uuid(nil), do: nil

  defp binaray_uuid_to_ecto_uuid(uuid) do
    Ecto.UUID.load!(uuid)
  end
end
