defmodule Radiator.Podcasts.EpisodeContributor do
  @moduledoc """
  Links a person to an episode and records their role.

  `role` is deliberately a string and not an enum: the podcast namespace knows
  far more roles than `host` and `guest`, and an unknown value must not abort
  the import. The translator writes it lower-cased.
  """

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Person

  postgres do
    table "episode_contributors"
    repo Radiator.Repo

    references do
      reference :episode, on_delete: :delete, index?: true
      reference :person, on_delete: :delete, index?: true
    end
  end

  actions do
    defaults [:read, :destroy]
    default_accept [:role]

    create :create do
      accept [:role, :episode_id, :person_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :role, :string

    timestamps()
  end

  relationships do
    belongs_to :episode, Episode, allow_nil?: false
    belongs_to :person, Person, allow_nil?: false
  end
end
