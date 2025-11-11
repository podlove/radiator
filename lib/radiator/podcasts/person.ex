defmodule Radiator.Podcasts.Person do
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "people"
    repo Radiator.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :real_name, :string do
      allow_nil? false
      public? false
    end

    attribute :nickname, :string do
      allow_nil? true
      public? false
    end

    attribute :email, :string do
      allow_nil? true
      public? false
    end

    attribute :telephone, :string do
      allow_nil? true
      public? false

      constraints match: ~r/^\+[1-9]\d{1,15}$/
    end

    timestamps()
  end

  relationships do
    has_many :personas, Radiator.Podcasts.Persona

    has_one :default_persona, Radiator.Podcasts.Persona do
      destination_attribute :person_id
      filter expr(default? == true)
    end
  end
end
