defmodule Radiator.Podcasts.Transcript do
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "transcripts"
    repo Radiator.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :text, :string do
      allow_nil? false
      public? true
    end

    attribute :start_time_ms, :integer do
      allow_nil? false
      public? true
    end

    attribute :end_time_ms, :integer do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :track, Radiator.Podcasts.Track
  end

  validations do
    validate compare(:start_time_ms,
               less_than: :end_time_ms,
               message: "Start time must be before end time"
             )
  end
end
