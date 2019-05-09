defmodule Radiator.Factory do
  use ExMachina.Ecto, repo: Radiator.Repo

  def network_factory do
    title = sequence(:title, &"Network ##{&1}")

    %Radiator.Directory.Network{
      title: title
    }
  end

  def podcast_factory do
    title = sequence(:title, &"My Podcast ##{&1}")

    %Radiator.Directory.Podcast{
      network: build(:network),
      title: title
    }
  end

  def unpublished_episode_factory do
    struct!(
      episode_factory(),
      %{
        published_at: DateTime.utc_now() |> DateTime.add(3600, :second)
      }
    )
  end

  def published_episode_factory do
    struct!(
      episode_factory(),
      %{
        published_at: DateTime.utc_now() |> DateTime.add(-3600, :second)
      }
    )
  end

  def episode_factory do
    title = sequence(:title, &"Episode ##{&1}")

    %Radiator.Directory.Episode{
      podcast: build(:podcast),
      title: title
    }
  end

  def enclosure_factory do
    %Radiator.Media.AudioFile{
      file: %{file_name: "example.mp3", updated_at: ~N[2019-04-24 09:41:47]},
      byte_length: 123,
      mime_type: "audio/mpeg"
    }
  end
end
