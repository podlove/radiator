defmodule Radiator.Factory do
  use ExMachina.Ecto, repo: Radiator.Repo

  import Radiator.Directory.Editor.Permission

  alias Radiator.Auth.User
  alias Radiator.Directory.{Network, Podcast, Episode}

  def user_factory do
    %User{
      name: "admin",
      email: "admin@example.com",
      display_name: "admin"
    }
  end

  # @deprecated use owned_by/2
  def make_owner(user = %User{}, network = %Network{}) do
    :ok = set_permission(user, network, :own)
    user
  end

  # @deprecated use owned_by/2
  def make_owner(user = %User{}, podcast = %Podcast{}) do
    :ok = set_permission(user, podcast, :own)
    user
  end

  def owned_by(network = %Network{}, user = %User{}) do
    :ok = set_permission(user, network, :own)
    network
  end

  def owned_by(podcast = %Podcast{}, user = %User{}) do
    :ok = set_permission(user, podcast, :own)
    podcast
  end

  def owned_by(episode = %Episode{}, user = %User{}) do
    :ok = set_permission(user, episode, :own)
    episode
  end

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
      title: title,
      published_at: DateTime.utc_now() |> DateTime.add(-3600, :second)
    }
  end

  def unpublished_podcast_factory do
    struct!(
      podcast_factory(),
      %{
        published_at: DateTime.utc_now() |> DateTime.add(3600, :second)
      }
    )
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
