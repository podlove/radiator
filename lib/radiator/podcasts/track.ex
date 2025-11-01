defmodule Radiator.Podcasts.Track do
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tracks"
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
    has_many :transcripts, Radiator.Podcasts.Transcript
    belongs_to :episode, Radiator.Podcasts.Episode

    belongs_to :persona, Radiator.Podcasts.Persona do
      allow_nil? true
    end
  end
end
