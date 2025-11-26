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
  end

  identities do
    identity :handle, [:handle]

    # identity :one_default_per_person, [:person_id] do
    #   where expr(default? == true)
    # end
  end
end
