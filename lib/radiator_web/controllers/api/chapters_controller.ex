defmodule RadiatorWeb.Api.ChaptersController do
  use RadiatorWeb, :controller

  alias Radiator.AudioMeta
  alias Radiator.Directory.Editor

  action_fallback(RadiatorWeb.Api.FallbackController)

  def create(conn, %{"audio_id" => audio_id, "chapter" => chapter_params}) do
    with {:ok, audio} <- Editor.get_audio(current_user(conn), audio_id),
         {:ok, chapter} <- AudioMeta.create_chapter(audio, chapter_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.api_audio_chapters_path(conn, :show, audio.id, chapter)
      )
      |> assign(:audio, audio)
      |> assign(:chapter, chapter)
      |> render("show.json")
    end
  end

  def update(conn, %{"audio_id" => audio_id, "id" => id, "chapter" => chapter_params}) do
    with {:ok, audio} <- Editor.get_audio(current_user(conn), audio_id),
         {:ok, chapter} <- AudioMeta.find_chapter(audio, id),
         {:ok, chapter} <- AudioMeta.update_chapter(chapter, chapter_params) do
      conn
      |> assign(:audio, audio)
      |> assign(:chapter, chapter)
      |> render("show.json")
    end
  end
end
