defmodule Radiator.Accounts.WebService do
  @moduledoc """
    Model for storing all kinds of information about a user's service.
    First implementation is for Raindrop.io
    In the future we may have support for other services and https://hexdocs.pm/polymorphic_embed/ might be a solution
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Accounts.User

  @raindrop_service_name "raindrop"

  schema "web_services" do
    field :service_name, :string

    embeds_one :data, RaindropService, on_replace: :delete, primary_key: false do
      field :access_token, :string, redact: true
      field :refresh_token, :string, redact: true
      field :expires_at, :utc_datetime
      # Show ID => Raindrop Collection ID
      field :collection_mappings, :map, default: %{}
    end

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(service, attrs) do
    service
    |> cast(attrs, [:service_name, :user_id])
    |> cast_embed(:data, required: true, with: &raindrop_changeset/2)
    |> validate_required([:service_name, :data])
  end

  def raindrop_changeset(service, attrs \\ %{}) do
    service
    |> cast(attrs, [:access_token, :refresh_token, :expires_at, :collection_mappings])
    |> validate_required([:access_token, :refresh_token, :expires_at])
  end

  def raindrop_service_name, do: @raindrop_service_name
end
