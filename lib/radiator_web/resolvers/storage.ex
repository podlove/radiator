defmodule RadiatorWeb.Resolvers.Storage do
  alias Radiator.Storage
  alias Radiator.Media
  alias Radiator.Directory

  def create_upload(_parent, %{filename: filename}, _resolution) do
    {:ok, upload_url} = Storage.get_upload_url(filename)
    {:ok, %{upload_url: upload_url}}
  end

  def upload_episode_audio(_parent, %{episode_id: id, audio: audio}, _) do
    case Directory.get_episode(id) do
      nil ->
        {:error, "Episode ID #{id} not found"}

      episode ->
        case Media.AudioFileUpload.upload(audio, episode) do
          {:ok, audio, _attachment} -> {:ok, audio}
          {:error, reason} -> {:error, "Upload to Episode ID #{id} failed: #{reason}"}
        end
    end
  end
end
