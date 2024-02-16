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

  @raw_sql_node_tree """
              SELECT uuid, content, parent_id, prev_id, 0 AS level
              FROM outline_nodes
              WHERE episode_id = 2 and parent_id is NULL
           UNION ALL
              SELECT outline_nodes.uuid, outline_nodes.content, outline_nodes.parent_id, outline_nodes.prev_id, node_tree.level + 1
              FROM outline_nodes
                 JOIN node_tree ON outline_nodes.parent_id = node_tree.uuid
        """
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

    # node_tree_recursion_query =
    #   Node
    #   |> join(:inner, [n], nd in "node_tree", on: n.parent_id == nd.uuid)
    #   |> fragmet("JOIN node_tree ON outline_nodes.parent_id = node_tree.uuid")
    #   |> select([n], %{uuid: n.uuid, content: n.content, parent_id: n.parent_id, prev_id: n.prev_id, level: fragment("'node_tree.level + 1'")})


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
      |> select([n], %{uuid: n.uuid, content: n.content, parent_id: n.parent_id, prev_id: n.prev_id, level: 0})
      |> Repo.all()


      tree2 = Node
      |> recursive_ctes(true)
      |> with_cte("node_tree", as: fragment(@raw_sql_node_tree))
      |> Repo.all()

    {:ok, tree, tree2}
  end



  # WITH RECURSIVE cte AS (
  #       SELECT uuid, content, parent_id, prev_id, 0 AS level
  #       FROM outline_nodes
  #       WHERE episode_id = 2 and parent_id is NULL
  #    UNION ALL
  #       SELECT outline_nodes.uuid, outline_nodes.content, outline_nodes.parent_id, outline_nodes.prev_id, cte.level + 1
  #       FROM outline_nodes
  #          JOIN cte ON outline_nodes.parent_id = cte.uuid
  # )
  # SELECT * FROM cte;
  #

  #
  #  WITH RECURSIVE "node_tree" AS (
  #       SELECT so0."uuid" AS "uuid", so0."content" AS "content", so0."parent_id" AS "parent_id", so0."prev_id" AS "prev_id", 0 AS "level"
  #       FROM "outline_nodes" AS so0
  #       WHERE (so0."parent_id" IS NULL) AND (so0."episode_id" = $1)
  #     UNION ALL (
  #       SELECT so0."uuid", so0."content", so0."parent_id", so0."prev_id", 'node_tree.level + 1'
  #     FROM "outline_nodes" AS so0
  #   INNER JOIN "node_tree" AS sn1 ON so0."parent_id" = sn1."uuid")) SELECT o0."uuid", o0."content", o0."creator_id", o0."parent_id", o0."prev_id", o0."episode_id", o0."inserted_at", o0."updated_at" FROM "outline_nodes" AS o0





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
