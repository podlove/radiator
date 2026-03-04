defmodule Radiator.Podcasts.Track do
  @moduledoc """
  The track resource, mostly a voice in the podcast
  """
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.EpisodeParticipant
  alias Radiator.Podcasts.Transcript

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
    has_many :transcripts, Transcript
    belongs_to :episode, Episode

    belongs_to :episode_participant, EpisodeParticipant do
      allow_nil? false
    end
  end
end
