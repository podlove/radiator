defmodule Radiator.Factory do
  use ExMachina.Ecto, repo: Radiator.Repo

  def podcast_factory do
    title = sequence(:title, &"My Podcast ##{&1}")

    %Radiator.Directory.Podcast{
      title: title
    }
  end
end
