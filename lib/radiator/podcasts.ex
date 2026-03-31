defmodule Radiator.Podcasts do
  @moduledoc false

  use Ash.Domain, otp_app: :radiator, extensions: [AshPhoenix, AshAdmin.Domain]

  require Ash.Query

  alias Radiator.People.Persona

  forms do
    form :create_episode, args: [:podcast_id]
  end

  admin do
    show? true
  end

  resources do
    resource Radiator.Podcasts.Podcast do
      define :create_podcast, action: :create
      define :read_podcasts, action: :read
      define :get_podcast_by_id, action: :read, get_by: :id
      define :update_podcast, action: :update
      define :destroy_podcast, action: :destroy
    end

    resource Radiator.Podcasts.Episode do
      define :read_episodes, action: :read
      define :create_episode, action: :create
      define :get_episode_by_id, action: :read, get_by: :id
      define :update_episode, action: :update
      define :add_participant_to_episode, action: :update, args: [:add_participant]
      define :remove_participant_from_episode, action: :update, args: [:remove_participant]
      define :begin_scheduling, action: :begin_scheduling
      define :finalize_scheduling, action: :finalize_scheduling
      define :back_to_scheduling, action: :back_to_scheduling
    end

    resource Radiator.Podcasts.Chapter
    resource Radiator.Podcasts.License
    resource Radiator.Podcasts.Transcript
    resource Radiator.Podcasts.Track

    resource Radiator.Podcasts.Episode.Scheduling do
      define :start_scheduling, action: :create
      define :get_by_episode, action: :by_episode
      define :add_proposal, action: :add_proposal
      define :remove_proposal, action: :remove_proposal
      define :vote, action: :vote
      define :remove_vote, action: :remove_vote
      define :finalize, action: :finalize
      define :reopen, action: :reopen
    end

    resource Radiator.Podcasts.EpisodeParticipant
    resource Radiator.Podcasts.Role
  end

  def read_podcast_participants(podcast_id) do
    Persona
    |> Ash.Query.filter(exists(episodes, podcast_id == ^podcast_id))
    |> Ash.read!()
  end
end
