defmodule Radiator.Podcasts.Person do
  @moduledoc """
  A person credited on podcasts and episodes.

  A true entity: the same person across every episode, referenced by ID. It
  hangs off the owner rather than off a single podcast — a `podcast_id` would
  cement the idea that a person can belong to only one show.

  The feed offers no stable person ID: `podcast:person` has none at all, and
  only a quarter of `atom:contributor` entries carry an `atom:uri`. Dedup
  therefore runs on `normalized_name` — a heuristic, but the only one the feed
  affords.
  """

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  alias Radiator.Accounts.User

  @default_accept_attributes [
    :name,
    :uri,
    :image_url
  ]

  postgres do
    table "persons"
    repo Radiator.Repo

    references do
      reference :user, on_delete: :delete, index?: true
    end
  end

  actions do
    defaults [:read, :destroy]
    default_accept @default_accept_attributes

    create :create do
      accept @default_accept_attributes ++ [:user_id]

      change Radiator.Podcasts.Person.Changes.NormalizeName
    end

    create :upsert_from_feed do
      accept @default_accept_attributes ++ [:user_id]

      upsert? true
      upsert_identity :unique_name_per_user
      upsert_fields {:replace_all_except, [:id, :inserted_at, :user_id, :normalized_name]}

      change Radiator.Podcasts.Person.Changes.NormalizeName
    end
  end

  @doc """
  The canonical form a person's name is deduplicated by.

  Public because the feed translator has to key its contributions by the same
  value the resource stores; two copies of this rule would drift.
  """
  def normalize(name), do: name |> to_string() |> String.trim() |> String.downcase()

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :normalized_name, :string, allow_nil?: false
    attribute :uri, :string
    attribute :image_url, :string

    timestamps()
  end

  relationships do
    belongs_to :user, User, allow_nil?: false
  end

  identities do
    identity :unique_name_per_user, [:user_id, :normalized_name]
  end
end
