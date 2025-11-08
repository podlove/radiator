defmodule Radiator.Podcasts.Role do
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "roles"
    repo Radiator.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? false
    end

    timestamps()
  end

  relationships do
    has_many :episode_personas, Radiator.Podcasts.EpisodePersona
  end
end
