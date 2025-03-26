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
       Radiator.Accounts.connect_show_with_raindrop(1, 23, 42)
    """
    def connect_show_with_raindrop(user_id, show_id, collection_id) do
      case get_raindrop_tokens(user_id) do
        nil ->
          {:error, "No Raindrop tokens found"}

        %{data: data} = service ->
        # send command to create node for raindrop in inbox container of show
          show = Radiator.Podcast.get_show!(show_id)
          command = Radiator.Outline.Command.build(
              "insert_node",
              %{
                "title" => "raindrop",
                "content" => "raindrop",
                "container_id" => show.inbox_node_container_id,
                "parent_id" => nil
              },
              nil,
              Ecto.UUID.generate()
            )
          Radiator.Outline.CommandQueue.enqueue(command)

          data =
            Map.update!(data, :collection_mappings, fn mappings ->
              Map.put(mappings, show_id_to_collection_id(show_id), collection_id)
            end)
            |> Map.from_struct()

          service
          |> WebService.changeset(%{data: data})
          |> Repo.update()
      end
    end

    defp show_id_to_collection_id(show_id) when is_integer(show_id), do: Integer.to_string(show_id)
    defp show_id_to_collection_id(show_id), do: show_id
end
