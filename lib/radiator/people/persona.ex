defmodule Radiator.People.Persona do
  @moduledoc """
  The persona resource.
  """
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.People,
    data_layer: AshPostgres.DataLayer

  alias Radiator.Accounts.User
  alias Radiator.People.Person
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.EpisodeParticipant

  postgres do
    table "personas"
    repo Radiator.Repo

    references do
      reference :user, on_delete: :nilify
    end
  end

  @default_accept_attributes [
    :public_name,
    :handle,
    :description,
    :avatar_png,
    :user_id
  ]

  code_interface do
    define :get_by_user, action: :by_user, args: [:user_id]
  end

  actions do
    defaults [:read, :destroy, :update]
    default_accept @default_accept_attributes

    create :create do
      accept @default_accept_attributes ++ [:person_id]
    end

    read :by_user do
      description "Get a persona by the linked user's id"
      get? true
      argument :user_id, :uuid, allow_nil?: false

      filter expr(user_id == ^arg(:user_id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :public_name, :string do
      allow_nil? false
      public? true
    end

    attribute :handle, :string do
      allow_nil? false
      public? false
    end

    attribute :description, :string do
      allow_nil? true
      public? true
    end

    attribute :avatar_png, :binary do
      allow_nil? true
      public? true
    end

    attribute :default?, :boolean do
      public? false
    end

    attribute :user_id, :uuid do
      allow_nil? true
      public? true
    end
  end

  relationships do
    belongs_to :person, Person

    belongs_to :user, User do
      allow_nil? true
      define_attribute? false
    end

    many_to_many :episodes, Episode do
      through EpisodeParticipant
      public? true
    end
  end

  identities do
    identity :handle, [:handle]
    identity :unique_user, [:user_id]
  end
end
