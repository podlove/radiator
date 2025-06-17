defmodule Radiator.Accounts.WebService do
  @moduledoc """
    Model for storing all kinds of information about a user's service.
    Currently supports Raindrop.io integration with potential for future service expansions
    using polymorphic embeds.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Accounts.User
  alias Radiator.Accounts.WebService.RaindropService

  @service_types ["raindrop"]
  @raindrop_service_name "raindrop"

  schema "web_services" do
    field :service_name, :string
    field :last_sync, :utc_datetime

    embeds_one :data, RaindropService, on_replace: :delete

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for WebService.
  """
  def changeset(service, attrs) do
    service
    |> cast(attrs, [:service_name, :user_id, :last_sync])
    |> cast_embed(:data, required: true)
    |> validate_required([:service_name, :user_id, :data])
    |> validate_inclusion(:service_name, @service_types)
    |> validate_last_sync_not_in_future()
    |> foreign_key_constraint(:user_id)
  end

  def raindrop_service_name, do: @raindrop_service_name

  @doc """
  Updates the last_sync timestamp for a web service.
  """
  def update_last_sync(%__MODULE__{} = service, sync_time \\ nil) do
    sync_time = sync_time || DateTime.utc_now() |> DateTime.truncate(:second)

    service
    |> changeset(%{last_sync: sync_time})
  end

  defp validate_last_sync_not_in_future(changeset) do
    case get_change(changeset, :last_sync) do
      nil ->
        changeset

      last_sync ->
        now = DateTime.utc_now()

        if DateTime.compare(last_sync, now) == :gt do
          add_error(changeset, :last_sync, "cannot be in the future")
        else
          changeset
        end
    end
  end
end
