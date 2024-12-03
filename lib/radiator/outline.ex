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

  alias Radiator.Outline.Node
  alias Radiator.Outline.NodeRepoResult
  alias Radiator.Outline.NodeRepository
  alias Radiator.Outline.Validations, as: NodeValidator
  alias Radiator.Podcast
  alias Radiator.Podcast.Episode
  alias Radiator.Repo

  require Logger

  @doc """
  Returns a list of direct child nodes in correct order.
  """
  def order_child_nodes(nil), do: []

  def order_child_nodes(%Node{} = node) do
    node
    |> NodeRepository.get_all_siblings()
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
  def insert_node(%{"show_id" => _show_id} = attrs) do
    Repo.transaction(fn ->
      episode_id = attrs["episode_id"]
      prev_id = attrs["prev_id"]
      parent_id = convert_parent_id_to_intern(attrs["parent_id"], episode_id)

      prev_node = NodeRepository.get_node_if(prev_id)
      parent_node = find_parent_node(prev_node, parent_id)

      # find Node which has been previously connected to prev_node
      next_node = NodeRepository.get_next_node(episode_id, prev_id, get_node_id(parent_node))

      with true <- parent_and_prev_consistent?(parent_node, prev_node),
           true <- episode_valid?(episode_id, parent_node, prev_node),
           {:ok, node} <-
             attrs
             |> set_parent_id_if(parent_node)
             |> NodeRepository.create_node(),
           {:ok, _node_to_move} <-
             NodeRepository.move_node_if(next_node, get_node_id(parent_node), node.uuid) do
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

  defp convert_parent_id_to_intern(nil, episode_id) do
    {episode_root, _} = NodeRepository.get_virtual_nodes_for_episode(episode_id)
    episode_root.uuid
  end
  
  defp convert_parent_id_to_intern(parent_id, _episode_id), do: parent_id

  def insert_node(%{"episode_id" => episode_id} = attrs) do
    %Episode{show_id: show_id} = Podcast.get_episode!(episode_id)

    attrs
    |> Map.put("show_id", show_id)
    |> insert_node()
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
          prev_node = NodeRepository.get_prev_node(node)
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
          parent_node = NodeRepository.get_parent_node(node)
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
          prev_node = NodeRepository.get_prev_node(node)
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
          next_node = NodeRepository.get_next_node(node)
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
        parent_node = NodeRepository.get_parent_node(node)

        case NodeValidator.validate_consistency_for_move(
               node,
               new_prev_id,
               new_parent_id,
               parent_node
             ) do
          {:error, error} ->
            {:error, error}

          {:ok, node} ->
            prev_node = NodeRepository.get_prev_node(node)
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
      |> NodeRepository.get_parent_node()
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
    Splits a node at the given position. The content of the node will be split,
    the original node will be updated with the content before the split and a new
    node will be created with the content after the split.

    The split is a selection with a start and stop index. What is in between will be
    deleted.
  """
  def split_node(_node_id, {start, stop}) when start > stop do
    {:error, :invalid_range}
  end

  def split_node(node_id, {start, stop}) do
    # missing transaction!!
    case NodeRepository.get_node(node_id) do
      nil ->
        {:error, :not_found}

      node ->
        {orig_node_content, new_node_content} = multisplit(node.content, start, stop)

        {:ok, updated_node} =
          node
          |> Node.update_content_changeset(%{content: orig_node_content})
          |> Repo.update()

        node_attrs = %{
          "content" => new_node_content,
          "episode_id" => node.episode_id,
          "parent_id" => node.parent_id,
          "prev_id" => node.uuid
        }

        {:ok, %NodeRepoResult{node: new_node, next: old_next_node}} =
          insert_node(node_attrs)

        {:ok,
         %NodeRepoResult{
           node: updated_node,
           next: new_node,
           episode_id: updated_node.episode_id,
           old_next: get_node_result_info(old_next_node)
         }}
    end
  end

  defp multisplit(nil, _start, _stop), do: {"", ""}

  defp multisplit(string, start, stop) do
    {first, _} = String.split_at(string, start)
    {_, last} = String.split_at(string, stop)

    {first, last}
  end

  @doc """
  Removes a node from the tree and deletes it from the repository.
  Recursivly deletes all children if there are some.
  ## Examples

      iex> remove_node(node)
      { %NodeRepoResult{} }

  """
  def remove_node(%Node{} = node) do
    next_node = NodeRepository.get_next_node(node)
    prev_node = NodeRepository.get_prev_node(node)

    {:ok, updated_next_node} =
      NodeRepository.move_node_if(next_node, node.parent_id, get_node_id(prev_node))

    # no tail recursion but we dont have too much levels in a tree
    all_children = node |> NodeRepository.get_all_siblings()

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
      next: get_node_result_info(updated_next_node),
      children: all_children ++ recursive_deleted_children,
      episode_id: node.episode_id
    }
  end

  @doc """

  ## Examples
      Returns the node above the given node, above in the sense of the expanced outline tree.
      iex> get_node_above(node_id)
      %Node{uuid: "074b755d-d095-4b9c-8445-ef1f7ea76d54"}
  """
  def get_node_above(node_id) do
    node =
      NodeRepository.get_node!(node_id)
      |> Repo.preload(:parent)
      |> Repo.preload(:prev)

    if node.prev_id do
      reverse_children =
        node.prev
        |> order_child_nodes()
        |> Enum.reverse()

      if Enum.empty?(reverse_children) do
        node.prev
      else
        hd(reverse_children)
      end
    else
      node.parent
    end
  end

  @doc """

  ## Examples
      Returns the node below the given node, below in the sense of the expanced outline tree.
      iex> get_node_below(node_id)
      %Node{uuid: "074b755d-d095-4b9c-8445-ef1f7ea76d54"}
  """
  def get_node_below(node_id) do
    node =
      NodeRepository.get_node!(node_id)
      |> Repo.preload(:parent)
      |> Repo.preload(:prev)

    children = node |> order_child_nodes()

    if Enum.empty?(children) do
      next_node = NodeRepository.get_next_node(node)

      if next_node do
        next_node
      else
        NodeRepository.get_next_node(node.parent)
      end
    else
      hd(children)
    end
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

  # low level function to move a node
  defp do_move_node(node, new_prev_id, new_parent_id, prev_node, parent_node) do
    node_repo_result = %NodeRepoResult{
      node: get_node_result_info(node),
      episode_id: node.episode_id
    }

    Repo.transaction(fn ->
      old_next_node =
        NodeRepository.get_node_by_parent_and_prev(
          get_node_id(parent_node),
          node.uuid,
          node.episode_id
        )

      new_next_node =
        NodeRepository.get_node_by_parent_and_prev(new_parent_id, new_prev_id, node.episode_id)

      {:ok, node} = NodeRepository.move_node_if(node, new_parent_id, new_prev_id)

      {:ok, old_next_node} =
        NodeRepository.move_node_if(
          old_next_node,
          get_parent_id_if(old_next_node),
          get_node_id(prev_node)
        )

      {:ok, new_next_node} =
        NodeRepository.move_node_if(new_next_node, new_parent_id, get_node_id(node))

      Map.merge(node_repo_result, %{
        node: get_node_result_info(node),
        old_next: get_node_result_info(old_next_node),
        old_prev: get_node_result_info(prev_node),
        next: get_node_result_info(new_next_node)
      })
    end)
  end

  defp get_parent_id_if(nil), do: nil
  defp get_parent_id_if(%Node{parent_id: parent_id}), do: parent_id

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

    moved_children =
      if Enum.empty?(new_children) do
        []
      else
        [first_of_new_children | tail_of_new_children] = new_children

        {:ok, moved_first_child} =
          NodeRepository.move_node_if(
            first_of_new_children,
            node.uuid,
            get_node_id(last_of_old_children)
          )

        Enum.map(tail_of_new_children, fn n ->
          {:ok, child_move_result} = NodeRepository.move_node_if(n, node.uuid, n.prev_id)
          child_move_result
        end) ++ [moved_first_child]
      end

    result =
      main_move_result
      |> Map.put(:children, moved_children)
      |> Map.put(:old_next, nil)

    {:ok, result}
  end

  defp do_move_up(%Node{}, nil), do: {:error, :no_previous_node}

  defp do_move_up(
         %Node{episode_id: episode_id, parent_id: parent_id} = node,
         %Node{} = prev_node
       ) do
    next_node = NodeRepository.get_next_node(episode_id, node.uuid, parent_id)

    {:ok, updated_node} = NodeRepository.move_node_if(node, parent_id, prev_node.prev_id)
    {:ok, updated_prev_node} = NodeRepository.move_node_if(prev_node, parent_id, node.uuid)
    {:ok, updated_next_node} = NodeRepository.move_node_if(next_node, parent_id, prev_node.uuid)

    %NodeRepoResult{
      node: get_node_result_info(updated_node),
      episode_id: episode_id,
      old_prev: get_node_result_info(updated_prev_node),
      old_next: get_node_result_info(updated_next_node)
    }
  end

  defp do_move_down(%Node{}, nil), do: {:error, :no_next_node}

  defp do_move_down(
         %Node{episode_id: episode_id, parent_id: parent_id} = node,
         %Node{} = next_node
       ) do
    new_next_node = NodeRepository.get_next_node(next_node)

    {:ok, updated_next_node} = NodeRepository.move_node_if(next_node, parent_id, node.prev_id)
    {:ok, updated_node} = NodeRepository.move_node_if(node, parent_id, next_node.uuid)

    {:ok, updated_new_next_node} =
      NodeRepository.move_node_if(new_next_node, parent_id, node.uuid)

    %NodeRepoResult{
      node: get_node_result_info(updated_node),
      episode_id: episode_id,
      old_next: get_node_result_info(updated_next_node),
      next: get_node_result_info(updated_new_next_node)
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
end
