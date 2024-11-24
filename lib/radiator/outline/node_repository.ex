defmodule Radiator.Outline.NodeRepository do
  @moduledoc """
    Repository functions for the Node module.
    Simple not tree aware node database actions. Mostly used internal and by tests.
  """
  import Ecto.Query, warn: false

  alias Radiator.Outline.Node
  alias Radiator.Repo

  @doc """
  Creates a node in the repository.

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
  end

  @doc """
  Deletes a node from the repository.

  ## Examples

      iex> delete_node(%{field: value})
      {:ok, %Node{}}

      iex> delete_node(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def delete_node(%Node{} = node) do
    node
    |> Repo.delete()
  end

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
  Returns the list of nodes for an episode.

  ## Examples

      iex> list_nodes_by_episode(123)
      [%Node{}, ...]

  """

  def list_nodes_by_episode(episode_id) do
    Node
    |> where([p], p.episode_id == ^episode_id)
    |> Repo.all()
    |> Enum.group_by(& &1.parent_id)
    |> Enum.map(fn {_parent_id, children} -> Radiator.Outline.order_sibling_nodes(children) end)
    |> List.flatten()
  end

  @doc """
  Returns the list of nodes for a show.

  ## Examples

      iex> _list_nodes_by_show(123)
      [%Node{}, ...]

  """

  def _list_nodes_by_show(show_id) do
    Node
    |> where([p], p.show_id == ^show_id)
    |> Repo.all()
    # |> Enum.group_by(& &1.parent_id)
    # |> Enum.map(fn {_parent_id, children} -> Radiator.Outline.order_sibling_nodes(children) end)
    |> List.flatten()
  end

  @doc """
  Returns the the number of nodes for an episode

  ## Examples

      iex> count_nodes_by_episode(123)
      3

  """
  def count_nodes_by_episode(episode_id) do
    Node
    |> where([p], p.episode_id == ^episode_id)
    |> Repo.aggregate(:count)
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
  Gets a single node where id can be nil.

  Returns `nil` if the Node does not exist.

  ## Examples

      iex> get_node_if(123)
      %Node{}

      iex> get_node_if(456)
      nil

      iex> get_node_if(nil)
      nil

  """
  def get_node_if(nil), do: nil
  def get_node_if(node), do: get_node(node)

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
  Gets a single node defined by the given prev_id and parent_id.
  Returns `nil` if the Node cannot be found.
  ## Examples
            iex> get_node_by_parent_and_prev("5adf3b360fb0", "380d56cf")
            nil

            iex> get_node_by_parent_and_prev("5e3f5a0422a4", "b78a976d")
            %Node{uuid: "33b2a1dac9b1", parent_id: "5e3f5a0422a4", prev_id: "b78a976d"}
  """
  def get_node_by_parent_and_prev(parent_id, prev_id) do
    Node
    |> where_prev_node_equals(prev_id)
    |> where_parent_node_equals(parent_id)
    |> Repo.one()
  end

  @doc """
    Updates prev_id and parent_id of a node in the repository.
    If the node is nil, it returns `{:ok, nil}`.
    It expects the parent_id and prev_id to be valid node ids. Both might
    be nil but no validation is done at this level. The tree needs to stay consistent,
    so use this function with care.

    ## Examples
            iex> move_node_if(nil, "a312a2ee", nil)
            {:ok, nil}

            iex> move_node_if(%Node{uuid: "33b2a1dac9b1"}, "7afb-43a6-b3ea", "04ff8601")
            {:ok, %Node{uuid: "33b2a1dac9b1", parent_id: "7afb-43a6-b3ea", prev_id: "04ff8601"}}
  """
  def move_node_if(nil, _parent_node_id, _prev_node_id), do: {:ok, nil}

  def move_node_if(node, parent_id, prev_id) do
    node
    |> Node.move_node_changeset(%{
      parent_id: parent_id,
      prev_id: prev_id
    })
    |> Repo.update()
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

  @doc """
  get_next_node/1
  Returns the next node of a given node in the outline tree.

  ## Examples
        iex> get_next_node(%Node{prev_id: nil})
        nil

        iex> get_next_node(%Node{prev_id: 42})
        %Node{uuid: 42}
  """
  def get_next_node(%Node{episode_id: episode_id, uuid: node_id, parent_id: parent_id}) do
    get_next_node(episode_id, node_id, parent_id)
  end

  @doc """
  get_next_node/3
  Returns the next node of a node defined by episode, previd and parent_id in the outline tree.

  Since the previous id and the parent id of a node might be nil, we need to pass the episode_id
  to find the correct node.

  ## Examples
        iex> get_next_node(23, "33b2a1dac9b1", "9d76aad4")
        nil

        iex> get_next_node(42, "33b2a1dac9b1", "9d76aad4")
        %Node{episode_id: 42, prev_id: "33b2a1dac9b1", parent_id: "9d76aad4"}
  """
  def get_next_node(episode_id, prev_id, parent_id) do
    Node
    |> where(episode_id: ^episode_id)
    |> where_prev_node_equals(prev_id)
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
  def get_node_tree(nil), do: {:error, "episode_id is nil"}

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

  defp where_prev_node_equals(node, nil), do: where(node, [n], is_nil(n.prev_id))
  defp where_prev_node_equals(node, prev_id), do: where(node, [n], n.prev_id == ^prev_id)

  defp where_parent_node_equals(node, nil), do: where(node, [n], is_nil(n.parent_id))
  defp where_parent_node_equals(node, parent_id), do: where(node, [n], n.parent_id == ^parent_id)

  defp binaray_uuid_to_ecto_uuid(nil), do: nil

  defp binaray_uuid_to_ecto_uuid(uuid) do
    Ecto.UUID.load!(uuid)
  end
end
