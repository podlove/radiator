defmodule RadiatorWeb.Api.AudioFileController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Media

  def create(conn, %{"audio_file" => audio_file_params}) do
    with {:ok, audio_file} <- Media.create_audio_file(audio_file_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.api_audio_file_path(conn, :show, audio_file.audio_id, audio_file)
      )
      |> render("show.json", audio_file: audio_file)
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
