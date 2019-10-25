defmodule RadiatorWeb.Api.FileSlotController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  def index(conn, %{"audio_id" => audio_id}) do
    with user = current_user(conn),
         {:ok, audio} = Editor.get_audio(user, audio_id) do
      conn
      |> assign(:audio, audio)
      |> render("index.json")
    end
  end
end
