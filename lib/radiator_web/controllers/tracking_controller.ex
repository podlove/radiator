defmodule RadiatorWeb.TrackingController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Media.AudioFile

  require Logger

  # todo: "show" is not a suitable name for this, need to come up with a better name
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

  defp track_download(conn = %Plug.Conn{private: %{is_head: true}}, _) do
    conn
  end

  defp track_download(conn, file = %AudioFile{}) do
    Radiator.Tracking.Server.track_download(
      file: file,
      remote_ip: remote_ip(conn),
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
