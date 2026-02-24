defmodule Radiator.Podcasts.Role do
  @moduledoc """
  The role resource. A role is a person's role in a podcast.
  """
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  alias Radiator.Podcasts.EpisodeParticipant

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
    has_many :episode_participants, EpisodeParticipant
  end
end
