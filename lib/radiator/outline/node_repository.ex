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

      iex> list_nodes(123)
      [%Node{}, ...]

  """

  def list_nodes_by_episode(episode_id) do
    Node
    |> where([p], p.episode_id == ^episode_id)
    |> Repo.all()
  end

  @doc """
  Returns the the number of nodes for an episode

  ## Examples

      iex> count_nodes_by_episode(123)
      3

  """
  def count_nodes_by_episode(episode_id) do
    episode_id
    |> list_nodes_by_episode()
    |> Enum.count()
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
end
