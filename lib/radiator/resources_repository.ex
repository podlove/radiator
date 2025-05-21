defmodule Radiator.ResourcesRepository do
  @moduledoc """
  The Web context. All web related stuff, handing URLs,
  scraped Websites etc..
  """

  import Ecto.Query, warn: false

  alias Radiator.Outline.Node
  alias Radiator.Repo
  alias Radiator.Resources.Url

  require Logger

  @doc """
  Returns the list of urls of a given episode.

  ## Examples

      iex> list_urls_by_episode(episode_id)
      [%Url{}, ...]

  """
  def list_urls_by_episode(episode_id) do
    query =
      from u in Url,
        where: u.episode_id == ^episode_id

    Repo.all(query)
  end

  @doc """
  Gets a single url.

  Raises `Ecto.NoResultsError` if the Url does not exist.

  ## Examples

      iex> get_url!(123)
      %Url{}

      iex> get_url!(456)
      ** (Ecto.NoResultsError)

  """
  def get_url!(id), do: Repo.get!(Url, id)

  @doc """
    creates all URL entities for a node. Before all existing URLs for this
    node get deleted.
  """
  def rebuild_node_urls(node_id, url_attributes) do
    {:ok, created_urls} =
      Repo.transaction(fn ->
        _number_of_nodes = delete_urls_for_node(node_id)

        Enum.map(url_attributes, fn attributes ->
          {:ok, url} =
            attributes
            |> create_url()

          url
        end)
      end)

    created_urls
  end

  @doc """
  Creates a url.

  ## Examples

      iex> create_url(%{field: value})
      {:ok, %Url{}}

      iex> create_url(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_url(attrs \\ %{}) do
    %Url{}
    |> Url.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a url.

  ## Examples

      iex> update_url(url, %{field: new_value})
      {:ok, %Url{}}

      iex> update_url(url, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_url(%Url{} = url, attrs) do
    url
    |> Url.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a url.

  ## Examples

      iex> delete_url(url)
      {:ok, %Url{}}

      iex> delete_url(url)
      {:error, %Ecto.Changeset{}}

  """
  def delete_url(%Url{} = url) do
    Repo.delete(url)
  end

  @doc """
  Deletes all urls for a given node.
  Returns the number of deleted urls.
  ## Examples

      iex> delete_urls_for_node(node_id)
      42

  """
  def delete_urls_for_node(%Node{uuid: node_id}), do: delete_urls_for_node(node_id)

  def delete_urls_for_node(node_id) when is_binary(node_id) do
    query = from u in Url, where: u.node_id == ^node_id
    {number_of_nodes, nil} = Repo.delete_all(query)
    number_of_nodes
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking url changes.

  ## Examples

      iex> change_url(url)
      %Ecto.Changeset{data: %Url{}}

  """
  def change_url(%Url{} = url, attrs \\ %{}) do
    Url.changeset(url, attrs)
  end
end
