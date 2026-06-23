defmodule Radiator.People.Person do
  @moduledoc """
  The person resource.
  """
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.People,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "people"
    repo Radiator.Repo
  end

  @default_accept_attributes [
    :first_name,
    :last_name,
    :display_name,
    :homepage_url,
    :wikipedia_url,
    :bio
  ]

  actions do
    defaults [:read, :destroy, :update]
    default_accept @default_accept_attributes

    create :create do
      accept @default_accept_attributes
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :first_name, :string, allow_nil?: false, public?: true
    attribute :last_name, :string, allow_nil?: true, public?: true
    attribute :display_name, :string, allow_nil?: true, public?: true
    attribute :homepage_url, :string, allow_nil?: true, public?: true
    attribute :wikipedia_url, :string, allow_nil?: true, public?: true
    attribute :bio, :string, allow_nil?: true, public?: true

    timestamps()
  end

  relationships do
    has_one :user, Radiator.Accounts.User do
      destination_attribute :person_id
      public? true
    end
  end
end
