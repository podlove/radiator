defmodule Radiator.TrackingTest do
  use Radiator.DataCase

  alias Radiator.Repo
  alias Radiator.Tracking
  alias Radiator.Tracking.Download

  import Radiator.Factory

  @valid_ip "127.0.0.1"
  @valid_http_range "bytes=0-"
  @valid_user_agent "Castro/85 CFNetwork/758.5.3 Darwin/15.6.0"

  describe "downloads" do
    test "track_download/1 tracks an episode download" do
      episode = insert(:published_episode) |> Repo.preload(audio: :audio_files)
      [file] = episode.audio.audio_files

      {:ok, download} =
        Tracking.track_download(
          file: file,
          episode: episode,
          remote_ip: @valid_ip,
          user_agent: @valid_user_agent,
          time: DateTime.utc_now(),
          http_range: @valid_http_range
        )

      assert Repo.get(Download, download.id)
      assert download.client_name == "Castro"
      assert download.os_name == "iOS"
      assert download.request_id
      assert download.episode_id
      assert download.podcast_id
      assert download.network_id
      assert download.audio_id == episode.audio.id
      assert download.file_id == file.id
    end

    test "track_download/1 tracks an audio download within a network, without episode association" do
      network = insert(:network)
      audio = insert(:audio, network: network)
      [file] = audio.audio_files

      {:ok, download} =
        Tracking.track_download(
          file: file,
          network: network,
          remote_ip: @valid_ip,
          user_agent: @valid_user_agent,
          time: DateTime.utc_now(),
          http_range: @valid_http_range
        )

      assert Repo.get(Download, download.id)
      assert download.audio_id == audio.id
    end

    test "track_download/1 discards bot requests" do
      episode = insert(:published_episode) |> Repo.preload(audio: :audio_files)
      [file] = episode.audio.audio_files

      {:ok, response} =
        Tracking.track_download(
          file: file,
          episode: episode,
          remote_ip: @valid_ip,
          user_agent: "Googlebot",
          time: DateTime.utc_now(),
          http_range: @valid_http_range
        )

      assert response == :skipped_because_not_clean
      assert Repo.aggregate(Download, :count, :id) == 0
    end

    test "track_download/1 discards bot first-byte-requests" do
      episode = insert(:published_episode) |> Repo.preload(audio: :audio_files)
      [file] = episode.audio.audio_files

      {:ok, response} =
        Tracking.track_download(
          file: file,
          episode: episode,
          remote_ip: @valid_ip,
          user_agent: @valid_user_agent,
          time: DateTime.utc_now(),
          http_range: "bytes=0-1"
        )

      assert response == :skipped_because_not_clean
      assert Repo.aggregate(Download, :count, :id) == 0
    end

    @hours 3
    test "track_download/1 calculates hours since episode release" do
      episode =
        insert(:published_episode, %{
          published_at: DateTime.utc_now() |> DateTime.add(-:timer.hours(@hours), :millisecond)
        })
        |> Repo.preload(audio: :audio_files)

      [file] = episode.audio.audio_files

      {:ok, download} =
        Tracking.track_download(
          file: file,
          episode: episode,
          remote_ip: @valid_ip,
          user_agent: @valid_user_agent,
          time: DateTime.utc_now(),
          http_range: @valid_http_range
        )

      assert download.hours_since_published == @hours
    end
  end

  def create_episode_audio(episode) do
    upload = %Plug.Upload{
      path: "test/fixtures/pling.mp3",
      filename: "pling.mp3"
    }

    {:ok, audio, _} = Radiator.Media.AudioFileUpload.upload(upload, episode.audio)

    audio
  end
end
