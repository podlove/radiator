defmodule RadiatorWeb.Api.AudioFileController do
  use RadiatorWeb, :controller

  alias Radiator.Media

  action_fallback(RadiatorWeb.Api.FallbackController)

  def create(conn, %{"audio_file" => audio_file_params}) do
    case Media.create_audio_file(audio_file_params) do
      {:ok, audio_file} ->
        conn
        |> put_status(:created)
        |> put_resp_header(
          "location",
          Routes.api_audio_file_path(conn, :show, audio_file)
        )
        |> render("show.json", audio_file: audio_file)

      other ->
        other
    end
  end

  def show(conn, %{"id" => id}) do
    audio_file = Media.get_audio_file(id)

    case audio_file do
      nil ->
        {:error, :not_found}

      audio_file ->
        render(conn, "show.json", audio_file: audio_file)
    end
  end
end
