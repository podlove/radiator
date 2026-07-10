defmodule Radiator.Podcasts.EpisodeParticipant do
  @moduledoc """
  The episode participant resource which joins an episode with a user.
  """
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  alias Radiator.Accounts.User
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Role
  alias Radiator.Podcasts.Track

  postgres do
    table "episode_participants"
    repo Radiator.Repo
  end

  actions do
    defaults [:read, :create, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    timestamps()
  end

  relationships do
    belongs_to :episode, Episode do
      allow_nil? false
    end

    belongs_to :user, User do
      allow_nil? false
    end

    belongs_to :role, Role do
      allow_nil? true
    end

    has_one :track, Track do
      allow_nil? true
    end
  end

  identities do
    identity :one_user_per_episode, [:episode_id, :user_id]
  end
end
