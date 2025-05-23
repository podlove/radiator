defmodule Radiator.Accounts.WebService.RaindropService do
  @moduledoc """
  Embedded schema for raindrop service that handles OAuth tokens and collection mappings
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          access_token: String.t(),
          refresh_token: String.t(),
          expires_at: DateTime.t(),
          mappings: [Mapping.t()]
        }

  embedded_schema do
    field :access_token, :string, redact: true
    field :refresh_token, :string, redact: true
    field :expires_at, :utc_datetime

    embeds_many :mappings, Mapping, on_replace: :delete, primary_key: false do
      field :show_id, :integer
      field :collection_id, :integer
      field :node_id, Ecto.UUID
    end
  end

  # Add a changeset function for better encapsulation
  def changeset(raindrop_service, attrs) do
    raindrop_service
    |> cast(attrs, [:access_token, :refresh_token, :expires_at])
    |> cast_embed(:mappings, with: &mapping_changeset/2)
    |> validate_required([:access_token, :refresh_token, :expires_at])
  end

  defp mapping_changeset(mapping, attrs) do
    changeset =
      mapping
      |> cast(attrs, [:show_id, :collection_id, :node_id])
      |> validate_required([:show_id])

    # Make collection_id required only if node_id is not being set
    if get_change(changeset, :node_id) do
      changeset
    else
      validate_required(changeset, [:collection_id])
    end
  end
end
