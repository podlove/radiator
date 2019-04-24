defmodule Radiator.Media.AudioFileUpload do
  @moduledoc """
  Upload AudioFile files and attach them to either an episode or network.

  Usually you want to create an audio object at the same time as
  attaching the upload. This needs to happen in two steps (create,
  then update) because we need the entity id for the storage URL
  when storing the file.

  This uploader is a convenience around these two steps and wraps
  them in a transaction. This avoids zombie file entries in case
  something goes wrong.

  ## Examples

    iex> upload = %Plug.Upload{
    ...>   content_type: "audio/mpeg",
    ...>   filename: "ls013-ultraschall.mp3",
    ...>   path: "/tmp/ls013-ultraschall.mp3"
    ...> }
    iex> {:ok, audio, attachment} = Radiator.Media.AudioFileUpload.upload(upload, episode)

  """
  alias Ecto.Multi
  alias Radiator.Repo
  alias Radiator.Media.Audio
  alias Radiator.Directory.{Episode, Network}
  alias Radiator.Directory.Editor

  def upload(upload = %Plug.Upload{}, network = %Network{}) do
    {:ok, audio} = upload(upload)

    Editor.attach_audio_to_network(network, audio)
    |> case do
      {:ok, attachment} -> {:ok, audio, attachment}
      _ -> {:error, :failed}
    end
  end

  def upload(upload = %Plug.Upload{}, episode = %Episode{}) do
    {:ok, audio} = upload(upload)

    episode
    |> Editor.detach_all_audios_from_episode()
    |> Editor.attach_audio_to_episode(audio)
    |> case do
      {:ok, attachment} -> {:ok, audio, attachment}
      _ -> {:error, :failed}
    end
  end

  @spec upload(Plug.Upload.t()) :: {:ok, Radiator.Media.AudioFile.t()} | {:error, atom()}
  defp upload(upload = %Plug.Upload{}) do
    Multi.new()
    |> Multi.insert(:create_audio, create_audio_changeset())
    |> Multi.update(:audio, add_audio_file_changeset(upload))
    |> Repo.transaction()
    |> case do
      {:ok, %{audio: audio}} -> {:ok, audio}
      {:error, _, _, _} -> {:error, :upload_failed}
    end
  end

  defp create_audio_changeset do
    Audio.changeset(%Audio{}, %{})
  end

  defp add_audio_file_changeset(upload) do
    {:ok, %File.Stat{size: size}} = File.lstat(upload.path)
    mime_type = MIME.from_path(upload.path)

    fn %{create_audio: audio} ->
      Audio.changeset(audio, %{
        "title" => upload.filename,
        "file" => upload,
        "mime_type" => mime_type,
        "byte_length" => size
      })
    end
  end
end
