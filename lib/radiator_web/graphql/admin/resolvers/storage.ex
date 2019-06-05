defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Storage do
  use Radiator.Constants

  alias Radiator.Storage
  alias Radiator.Media
  alias Radiator.Directory.Editor

  def create_upload(_parent, %{filename: filename}, _resolution) do
    {:ok, upload_url} = Storage.get_upload_url(filename)
    {:ok, %{upload_url: upload_url}}
  end

  def upload_audio_file(_parent, %{audio_id: id, file: file}, %{
        context: %{authenticated_user: user}
      }) do
    case Editor.get_audio(user, id) do
      {:ok, audio} ->
        case Media.AudioFileUpload.upload(file, audio) do
          {:ok, audio_file, _attachment} -> {:ok, audio_file}
          {:error, reason} -> {:error, "Upload failed: #{reason}"}
        end

      @not_found_match ->
        @not_found_response

      @not_authorized_match ->
        @not_authorized_response
    end
  end
end
