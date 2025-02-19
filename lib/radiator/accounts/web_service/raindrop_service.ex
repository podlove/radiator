defmodule Radiator.Accounts.WebService.RaindropService do
  @moduledoc """
  embedded schema for raindrop service
  """
  # import Ecto.Changeset
  use Ecto.Schema

  embedded_schema do
    field :access_token, :string, redact: true
    field :refresh_token, :string, redact: true
    field :expires_at, :utc_datetime
    # Show ID => Raindrop Collection ID
    field :collection_mappings, :map, default: %{}

    embeds_many :mappings, Mapping, on_replace: :delete, primary_key: false do
      field :show_id, :string
      field :collection_id, :string
      field :node_id, Ecto.UUID
    end
  end
end
