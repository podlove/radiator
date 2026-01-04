defmodule Radiator.Podcasts.Episode.Scheduling do
  @moduledoc """
    Module for scheduling podcast episodes. Only for the phase when a episode is being scheduled.
  """
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  alias Radiator.Podcasts.Episode.Scheduling

  postgres do
    table "chapters"
    repo Radiator.Repo

    references do
      reference :episode
    end
  end

  actions do
    defaults [:read, :destroy, :create, :update]

    # create :start_scheduling do
    #   manual StartScheduling
    # end
    #

    create :start_scheduling do
      accept [:episode_id, :proposals]
    end

    default_accept [:proposals]
  end

  validations do
  end

  attributes do
    uuid_primary_key :id

    attribute :proposals, :map do
      description "a jsonb array of proposed dates and their votes per persona and score"
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :episode, Radiator.Podcasts.Episode do
      description "The episodes of the podcast"
      public? true
    end
  end

  identities do
    identity :unique_episode, [:episode_id], message: "episode already has a scheduling"
  end

  def start_scheduling_episode(episode_id, proposals) do
    Scheduling
    |> Ash.Changeset.for_create(:start_scheduling, %{
      episode_id: episode_id,
      proposals: proposals
    })
    |> Ash.create!()
  end

  def proposals_for_episode(_episode) do
    # to render a voting page
  end

  def vote_for_date(_episode, _persona, _date, _score) do
    # Implement voting logic here
    #
    # After
    # episode state == scheduling
    # nneds to have persons and at least one proposal
  end

  def vote_stats(_episode) do
  end

  def finish_scheduling_episode(_episode, _date) do
    # next state in episode
  end
end

defmodule StartScheduling do
  use Ash.Resource.ManualCreate

  def create(_changeset, _opts, _context) do
    # After
    # episode state == scheduling
    # nneds to have persons and at least one proposal
  end
end
