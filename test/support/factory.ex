defmodule Radiator.Factory do
  use ExMachina.Ecto, repo: Radiator.Repo

  import Radiator.Directory.Editor.Permission

  alias Radiator.Auth.User

  alias Radiator.Directory.{
    Editor,
    Network,
    Podcast,
    Episode,
    AudioPublication,
    UserProfile
  }

  alias Radiator.Contribution.Person

  def user_factory do
    %User{
      name: sequence(:name, &"me-#{&1}"),
      email: sequence(:email, &"me-#{&1}@foo.com"),
      profile: build(:profile)
    }
  end

  def profile_factory do
    %UserProfile{
      display_name: sequence(:display_name, &"Me-#{&1}")
    }
  end

  def person_factory do
    name = sequence("maxi_muster_")

    %Person{
      display_name: name
    }
  end

  def testuser_factory do
    username = sequence("signup_test_user_")
    %{username: username, password: sequence("pass_"), email: "#{username}@testhost.local"}
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

  @spec owned_by(
          %{
            __struct__:
              Radiator.Directory.AudioPublication
              | Radiator.Directory.Episode
              | Radiator.Directory.Network
              | Radiator.Directory.Podcast
          },
          Radiator.Auth.User.t()
        ) :: %{
          __struct__:
            Radiator.Directory.AudioPublication
            | Radiator.Directory.Episode
            | Radiator.Directory.Network
            | Radiator.Directory.Podcast
        }
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

  def owned_by(audio_publication = %AudioPublication{}, user = %User{}) do
    :ok = set_permission(user, audio_publication, :own)
    audio_publication
  end

  def publish(list) when is_list(list) do
    Enum.map(list, &publish/1)
  end

  def publish(episode = %Episode{}) do
    {:ok, episode} = Editor.Manager.publish(episode)
    episode
  end

  def publish(podcast = %Podcast{}) do
    {:ok, podcast} = Editor.Manager.publish(podcast)
    podcast
  end

  def publish_all(episode = %Episode{podcast: podcast}) do
    {:ok, episode} = Editor.Manager.publish(episode)
    {:ok, _podcast} = Editor.Manager.publish(podcast)
    episode
  end

  def network_factory do
    title = sequence(:title, &"Network ##{&1}")
    slug = sequence(:slug, &"network-#{&1}")

    %Radiator.Directory.Network{
      title: title,
      slug: slug
    }
  end

  def podcast_factory do
    title = sequence(:title, &"My Podcast ##{&1}")

    %Radiator.Directory.Podcast{
      network: build(:network),
      title: title
    }
  end

  def episode_factory() do
    title = sequence(:title, &"Episode ##{&1}")

    %Radiator.Directory.Episode{
      podcast: build(:podcast),
      audio: build(:audio),
      title: title
    }
  end

  def audio_publication_factory do
    title = sequence(:title, &"Publication ##{&1}")
    slug = sequence(:slug, &"publication-#{&1}")

    %Radiator.Directory.AudioPublication{
      network: build(:network),
      audio: build(:audio),
      publish_state: :published,
      published_at: DateTime.utc_now() |> DateTime.add(-3600, :second),
      title: title,
      slug: slug
    }
  end

  def audio_factory do
    %Radiator.Directory.Audio{
      duration: 3_723_000,
      audio_files: [build(:audio_file)]
    }
  end

  def empty_audio_factory do
    %Radiator.Directory.Audio{
      duration: 3_723_000
    }
  end

  def chapter_factory do
    %Radiator.AudioMeta.Chapter{
      start: sequence(:start, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
      title: sequence(:title, &"chapter #{&1}"),
      link: sequence(:link, &"http://example.com/#{&1}"),
      audio: build(:audio)
    }
  end

  # @deprecated, use audio_file_factory
  def enclosure_factory do
    %Radiator.Media.AudioFile{
      file: %{file_name: "example.mp3", updated_at: ~N[2019-04-24 09:41:47]},
      byte_length: 123,
      mime_type: "audio/mpeg"
    }
  end

  def audio_file_factory do
    %Radiator.Media.AudioFile{
      file: %{file_name: "example.mp3", updated_at: ~N[2019-04-24 09:41:47]},
      byte_length: 123,
      mime_type: "audio/mpeg"
    }
  end
end
