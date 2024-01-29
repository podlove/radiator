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


  ##
  def create_node(attrs, %{id: id}) do

    |> Node.changeset(attrs)
    |> Repo.insert()
    |> broadcast_node_action(:insert)
  end

  def

  def open_account(account_params) do
      changeset = account_opening_changeset(account_params)

      if changeset.valid? do
        account_uuid = UUID.uuid4()

        dispatch_result =
          %OpenAccount{
            initial_balance: changeset.changes.initial_balance,
            account_uuid: account_uuid
          }
          |> Router.dispatch()

        case dispatch_result do
          :ok ->
            {
              :ok,
              %Account{
                uuid: account_uuid,
                current_balance: changeset.changes.initial_balance
              }
            }

          reply ->
            reply
        end
      else
        {:validation_error, changeset}
      end
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
