defmodule Radiator.Accounts.Raindrop do
  @moduledoc """
    Raindrop related functions for a user.
    TODO: Think of a better name.
  """

  import Ecto.Query, warn: false
  alias Radiator.Repo

  alias Radiator.Accounts.WebService

  @doc """
    Get the user's Raindrop tokens if they exist.

  ## Examples

      iex> get_raindrop_tokens(23)
      %WebService{}

      iex> get_raindrop_tokens(42)
      nil

  """
  def get_raindrop_tokens(user_id) do
    service_name = WebService.raindrop_service_name()

    WebService
    |> where([w], w.user_id == ^user_id)
    |> where([w], w.service_name == ^service_name)
    |> Repo.one()
  end

  @doc """
  Sets a users optional Raindrop tokens and expiration time.
  Given a user id, access token, refresh token, and expiration time,

  ## Examples

      iex> update_raindrop_tokens(23, "11r4", "11vb", ~U[2024-11-02 11:54:31Z])
      {:ok, %User{}}

      iex> update_raindrop_tokens(42, "11r4", "11vb", ~U[2024-11-02 11:54:31Z])
      {:error, %Ecto.Changeset{}}

  """
  def update_raindrop_tokens(
        user_id,
        raindrop_access_token,
        raindrop_refresh_token,
        raindrop_expires_at
      ) do
    %WebService{}
    |> WebService.changeset(%{
      service_name: WebService.raindrop_service_name(),
      user_id: user_id,
      data: %{
        access_token: raindrop_access_token,
        refresh_token: raindrop_refresh_token,
        expires_at: raindrop_expires_at
      }
    })
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :created_at]},
      conflict_target: [:user_id, :service_name],
      set: [updated_at: DateTime.utc_now()]
    )
  end

  @doc """
  Connects a show with a Raindrop collection by adding a new mapping entry.

  ## Examples

      iex> connect_show_with_raindrop(1, 23, 42)
      {:ok, %WebService{}}

      iex> connect_show_with_raindrop(999, 23, 42)
      {:error, "No Raindrop tokens found"}
  """
  def connect_show_with_raindrop(user_id, show_id, collection_id, node_id \\ nil) do
    case get_raindrop_tokens(user_id) do
      nil ->
        {:error, "No Raindrop tokens found"}

      %{data: data} = service ->
        updated_mappings = update_mappings(data.mappings, show_id, collection_id, node_id)

        service
        |> WebService.changeset(%{
          data: %{
            access_token: data.access_token,
            refresh_token: data.refresh_token,
            expires_at: data.expires_at,
            mappings: updated_mappings
          }
        })
        |> Repo.update()
    end
  end

  # Filter out any existing mapping with the same show_id and convert to maps
  defp update_mappings(mappings, show_id, collection_id, node_id) do
    mappings
    |> Enum.reject(fn mapping -> mapping.show_id == show_id end)
    |> Enum.map(&Map.from_struct/1)
    |> Kernel.++([%{show_id: show_id, node_id: node_id, collection_id: collection_id}])
  end
end
