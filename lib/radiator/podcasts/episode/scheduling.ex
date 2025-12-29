defmodule Radiator.Podcasts.Episode.Scheduling do
  @moduledoc """
    Module for scheduling podcast episodes. Only for the phase when a episode is being scheduled.
  """
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "chapters"
    repo Radiator.Repo

    references do
      reference :episode
    end
  end

  actions do
    defaults [:read, :destroy, :create, :update]

    default_accept [:proposals]
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

  def start_scheduling_episode(_episode, _date_proposals) do
    # Implement scheduling logic here
    # where to store the dates, and the votes?
    # create episode here?
    #
    # After
    # episode state == scheduling
    # nneds to have persons and at least one proposal
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
