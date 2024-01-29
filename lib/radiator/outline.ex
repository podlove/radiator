defmodule Radiator.Outline do
  @moduledoc """
  The Outline context.
  """

  import Ecto.Query, warn: false

  alias Radiator.Outline.Node
  alias Radiator.Outline.Notify
  alias Radiator.Repo

  def create(attrs \\ %{}, socket_id \\ nil) do
    attrs
    |> create_node()
    |> Notify.broadcast_node_action(:insert, socket_id)
  end

  def delete(%Node{} = node, socket_id \\ nil) do
    node
    |> delete_node()
    |> Notify.broadcast_node_action(:delete, socket_id)
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

      iex> list_nodes(123)
      [%Node{}, ...]

  """

  def list_nodes_by_episode(episode_id) do
    Node
    |> where([p], p.episode_id == ^episode_id)
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
  Creates a node.

  ## Examples

      iex> create_node(%{field: value})
      {:ok, %Node{}}

      iex> create_node(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_node(attrs \\ %{}, socket_id \\ nil) do
    %Node{}
    |> Node.insert_changeset(attrs)
    |> Repo.insert()
    |> Notify.broadcast_node_action(:insert, socket_id)
  end

  def create_node(attrs, %{id: id}) do
    %Node{creator_id: id}
    |> Node.insert_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a nodes content.

  ## Examples

      iex> update_node_content(node, %{content: new_value})
      {:ok, %Node{}}

      iex> update_node_content(node, %{content: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_node_content(%Node{} = node, attrs, socket_id \\ nil) do
    node
    |> Node.update_content_changeset(attrs)
    |> Repo.update()
    |> Notify.broadcast_node_action(:update, socket_id)
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
  end
end
