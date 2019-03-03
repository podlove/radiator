defmodule Radiator.Factory do
  use ExMachina.Ecto, repo: Radiator.Repo

  def podcast_factory do
    title = sequence(:title, &"My Podcast ##{&1}")

    %Radiator.Directory.Podcast{
      title: title
    }
  end

  def episode_factory do
    title = sequence(:title, &"Episode ##{&1}")

    %Radiator.Directory.Episode{
      podcast: build(:podcast),
      title: title
    }
  end
end
