defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Storage do
  use Radiator.Constants

  alias Radiator.Media
  alias Radiator.Directory.Editor

  def upload_audio_file(_parent, %{audio_id: id, file: file}, %{
        context: %{current_user: user}
      }) do
    case Editor.get_audio(user, id) do
      {:ok, audio} ->
        case Media.AudioFileUpload.upload(file, audio) do
          {:ok, audio_file} -> {:ok, audio_file}
          {:error, reason} -> {:error, "Upload failed: #{reason}"}
        end

      @not_found_match ->
        @not_found_response

      @not_authorized_match ->
        @not_authorized_response
    end
  end
end
