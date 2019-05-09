defmodule RadiatorWeb.TrackingController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Media.AudioFile

  require Logger

  def show(conn, %{"id" => id}) do
    case Directory.get_audio_file(id) do
      {:ok, audio} ->
        conn
        |> track_download(audio)
        |> put_status(301)
        |> redirect(external: AudioFile.url({audio.file, audio}))

      {:error, _} ->
        send_resp(conn, 404, "Not found")
    end
  end

  # todo: too much logic in controller
  # I don't want to pass conn down to the core but feel like I should
  # just pass down all the raw data I need there and do all processing
  # down there.
  defp track_download(conn = %Plug.Conn{private: %{is_head: true}}, _) do
    conn
  end

  defp track_download(conn, file = %AudioFile{}) do
    Radiator.Tracking.Server.track_download(
      file: file,
      request_id: request_id(conn),
      user_agent: user_agent(conn),
      time: DateTime.utc_now(),
      http_range: http_range(conn)
    )

    conn
  end

  defp user_agent(conn) do
    conn
    |> get_req_header("user-agent")
    |> List.first()
    |> case do
      user_agent when is_binary(user_agent) and byte_size(user_agent) > 0 -> user_agent
      _ -> "<blank>"
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

  defp request_id_plain(conn) do
    remote_ip(conn) <> user_agent(conn)
  end

  defp request_id(conn) do
    :crypto.hash(:sha256, request_id_plain(conn))
    |> Base.encode64(padding: false)
    |> String.slice(0..7)
  end
end
