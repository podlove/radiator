defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Storage do
  alias Radiator.Storage
  alias Radiator.Media
  alias Radiator.Directory.Editor

  @not_authorized_match {:error, :not_authorized}
  @not_authorized_response {:error, "Not Authorized"}

  @not_found_match {:error, :not_found}
  @not_found_response {:error, "Entity not found"}

  def create_upload(_parent, %{filename: filename}, _resolution) do
    {:ok, upload_url} = Storage.get_upload_url(filename)
    {:ok, %{upload_url: upload_url}}
  end

  def upload_episode_audio(_parent, %{episode_id: id, audio: audio}, %{
        context: %{authenticated_user: user}
      }) do
    case Editor.get_episode(user, id) do
      {:ok, episode} ->
        case Media.AudioFileUpload.upload(audio, episode) do
          {:ok, audio, _attachment} -> {:ok, audio}
          {:error, reason} -> {:error, "Upload to Episode ID #{id} failed: #{reason}"}
        end

      @not_found_match ->
        @not_found_response

      @not_authorized_match ->
        @not_authorized_response
    end
  end

  def upload_episode_audio(_parent, %{network_id: id, audio: audio}, %{
        context: %{authenticated_user: user}
      }) do
    case Editor.get_network(user, id) do
      {:ok, network} ->
        case Media.AudioFileUpload.upload(audio, network) do
          {:ok, audio, _attachment} -> {:ok, audio}
          {:error, reason} -> {:error, "Upload to etwork ID #{id} failed: #{reason}"}
        end

      @not_found_match ->
        @not_found_response

      @not_authorized_match ->
        @not_authorized_response
    end
  end
end
