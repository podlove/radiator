defmodule Radiator.Podcasts.EpisodePersona do
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "episode_personas"
    repo Radiator.Repo
  end

  attributes do
    uuid_primary_key :id

    timestamps()
  end

  relationships do
    belongs_to :episode, Radiator.Podcasts.Episode do
      allow_nil? false
    end

    belongs_to :persona, Radiator.Podcasts.Persona do
      allow_nil? false
    end

    belongs_to :role, Radiator.Podcasts.Role do
      allow_nil? true
    end

    has_one :track, Radiator.Podcasts.Track do
      allow_nil? true
    end
  end

  identities do
    identity :one_persona_per_episode, [:episode_id, :persona_id]
  end
end
