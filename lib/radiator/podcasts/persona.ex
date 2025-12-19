defmodule Radiator.Podcasts.Persona do
  @moduledoc """
  The persona resource.
  """
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "personas"
    repo Radiator.Repo
  end

  @default_accept_attributes [
    :public_name,
    :handle,
    :description,
    :avatar_png
  ]

  actions do
    defaults [:read, :destroy, :update]
    default_accept @default_accept_attributes

    create :create do
      accept @default_accept_attributes ++ [:person_id]
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
  end

  relationships do
    belongs_to :person, Radiator.Podcasts.Person

    many_to_many :episodes, Radiator.Podcasts.Episode do
      through Radiator.Podcasts.EpisodePersona
      public? true
    end
  end

  identities do
    identity :handle, [:handle]

    # identity :one_default_per_person, [:person_id] do
    #   where expr(default? == true)
    # end
  end
end
