defmodule RadiatorWeb.Api.FileSlotController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Storage
  alias Radiator.Directory.Editor

  def index(conn, %{"audio_id" => audio_id}) do
    with user <- current_user(conn),
         {:ok, audio} <- Editor.get_audio(user, audio_id),
         slots <- Storage.list_slots(audio) do
      conn
      |> assign(:audio, audio)
      |> assign(:slots, slots)
      |> render("index.json")
    end
  end

  # todo: send proper response if file_id is missing
  def fill(conn, %{"audio_id" => audio_id, "file_id" => file_id, "slot" => slot}) do
    with user <- current_user(conn),
         {:ok, audio} <- Editor.get_audio(user, audio_id),
         {:ok, file} <- Storage.get_file(file_id) do
      Storage.fill_slot(audio, slot, file)

      conn
      |> put_status(:created)
      |> json(%{resonse: "ok"})

      # conn
      # |> put_status(:created)
      # |> put_resp_header("location", ???)
      # |> render("show.json", %{???: ???})
    end
  end
end
