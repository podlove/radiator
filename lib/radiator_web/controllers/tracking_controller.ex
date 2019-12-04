defmodule RadiatorWeb.TrackingController do
  use RadiatorWeb, :controller

  alias Radiator.Directory

  alias Radiator.Directory.{
    Network,
    AudioPublication,
    Podcast,
    Episode
  }

  alias Radiator.Media.AudioFile

  require Logger

  def track_episode_file(
        conn,
        %{
          "podcast_slug" => podcast_slug,
          "episode_slug" => episode_slug,
          "file_id" => file_id
        }
      ) do
    with {:p, podcast = %Podcast{}} <- {:p, Directory.get_podcast_by_slug(podcast_slug)},
         {:e, episode = %Episode{}} <-
           {:e, Directory.get_episode_by_slug(podcast.id, episode_slug)},
         {:ok, file, slot} <- Directory.get_episode_file(episode, file_id) do
      conn
      |> track_download(podcast: podcast, episode: episode, slot: slot)
      |> put_status(301)
      |> redirect(external: Episode.enclosure_url(episode, slot.slot))
    else
      {:p, _} ->
        send_resp(conn, 404, "Podcast not found")

      {:e, _} ->
        send_resp(conn, 404, "Episode not found")

      o ->
        IO.inspect(o)
        send_resp(conn, 404, "Not found")
    end
  end

  # FIXME: slot rework
  def track_audio_publication_file(conn, %{
        "network_slug" => network_slug,
        "audio_publication_slug" => audio_publication_slug,
        "file_id" => file_id
      }) do
    with network = %Network{} <- Directory.get_network_by_slug(network_slug),
         audio_publication = %AudioPublication{} <-
           Directory.get_audio_publication_by_slug(audio_publication_slug),
         {:ok, audio_file} <- Directory.get_audio_file(file_id),
         true <- network.id == audio_publication.network_id do
      conn
      |> track_download(audio_publication: audio_publication, audio_file: audio_file)
      |> put_status(301)
      |> redirect(external: AudioFile.url({audio_file.file, audio_file}))
    else
      _ ->
        send_resp(conn, 404, "Not found")
    end
  end

  defp track_download(conn = %Plug.Conn{private: %{is_head: true}}, _) do
    conn
  end

  defp track_download(conn, podcast: podcast, episode: episode, slot: slot) do
    Radiator.Tracking.Server.track_download(
      podcast: podcast,
      episode: episode,
      slot: slot,
      remote_ip: remote_ip(conn),
      user_agent: user_agent(conn),
      time: DateTime.utc_now(),
      http_range: http_range(conn),
      referer: referer(conn)
    )

    conn
  end

  defp track_download(conn, audio_publication: audio_publication, slot: slot) do
    Radiator.Tracking.Server.track_download(
      audio_publication: audio_publication,
      slot: slot,
      remote_ip: remote_ip(conn),
      user_agent: user_agent(conn),
      time: DateTime.utc_now(),
      http_range: http_range(conn),
      referer: referer(conn)
    )

    conn
  end

  defp user_agent(conn) do
    conn
    |> get_req_header("user-agent")
    |> List.first()
    |> case do
      user_agent when is_binary(user_agent) and byte_size(user_agent) > 0 -> user_agent
      _ -> ""
    end
  end

  defp referer(conn) do
    conn
    |> get_req_header("referer")
    |> List.first()
    |> case do
      referer when is_binary(referer) and byte_size(referer) > 0 -> referer
      _ -> ""
    end
  end

  defp http_range(conn) do
    conn |> get_req_header("range") |> List.first()
  end

  defp remote_ip(conn) do
    conn.remote_ip
    |> :inet_parse.ntoa()
    |> to_string()
  end
end
