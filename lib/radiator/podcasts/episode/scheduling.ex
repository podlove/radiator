defmodule Radiator.Podcasts.Episode.Scheduling do
  def start_scheduling_episode(episode, date_proposals) do
    # Implement scheduling logic here
    # where to store the dates, and the votes?
    # create episode here?
    #
    # After
    # episode state == scheduling
    # nneds to have persons and at least one proposal
  end

  def proposals_for_episode(episode) do
    # to render a voting page
  end

  def vote_for_date(episode, persona, date, score) do
    # Implement voting logic here
    #
    # After
    # episode state == scheduling
    # nneds to have persons and at least one proposal
  end

  def vote_stats(episode) do
  end

  def finish_scheduling_episode(episode, date) do
    # next state in episode
  end
end
