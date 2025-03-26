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

    embeds_one :data, RaindropService, on_replace: :delete
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for WebService.
  """
  def changeset(service, attrs) do
    service
    |> cast(attrs, [:service_name, :user_id])
    |> cast_embed(:data, required: true)
    |> validate_required([:service_name, :user_id, :data])
    |> validate_inclusion(:service_name, @service_types)
    |> foreign_key_constraint(:user_id)
  end

  def raindrop_service_name, do: @raindrop_service_name
end
