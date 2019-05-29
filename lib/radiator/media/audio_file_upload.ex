defmodule Radiator.Media.AudioFileUpload do
  @moduledoc """
  Upload AudioFile files and attach them to an audio container.

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
      iex> {:ok, audio_file, attachment} = Radiator.Media.AudioFileUpload.upload(upload, audio)

  """
  alias Ecto.Multi
  alias Radiator.Repo
  alias Radiator.Media.AudioFile
  alias Radiator.Media.Attachment
  alias Radiator.Directory.{Audio, Editor}

  @doc """
  Upload audio file and attach it to audio object.

  `upload` parameter can be anything that the arc `store` function accepts, see https://github.com/stavro/arc#basics
  """
  @spec upload(any(), Audio.t()) ::
          {:ok, AudioFile.t(), Attachment.t()} | {:error, :failed}
  def upload(upload, audio = %Audio{}) do
    {:ok, audio_file} = upload(upload)

    audio
    |> Editor.attach_audio_file(audio_file)
    |> case do
      {:ok, attachment} -> {:ok, audio, attachment}
      _ -> {:error, :failed}
    end
  end

  @spec upload(Plug.Upload.t()) :: {:ok, Radiator.Media.AudioFile.t()} | {:error, atom()}
  defp upload(upload) do
    Multi.new()
    |> Multi.insert(:create_audio_file, create_audio_file_changeset())
    |> Multi.update(:audio_file, add_audio_file_changeset(upload))
    |> Repo.transaction()
    |> case do
      {:ok, %{audio_file: audio_file}} -> {:ok, audio_file}
      {:error, _, _, _} -> {:error, :upload_failed}
    end
  end

  defp create_audio_file_changeset do
    AudioFile.changeset(%AudioFile{}, %{})
  end

  defp add_audio_file_changeset(upload = %Plug.Upload{path: path, filename: filename})
       when is_binary(path) and is_binary(filename) do
    {:ok, %File.Stat{size: size}} = File.lstat(path)
    mime_type = MIME.from_path(path)

    fn %{create_audio_file: audio} ->
      AudioFile.changeset(audio, %{
        "title" => filename,
        "file" => upload,
        "mime_type" => mime_type,
        "byte_length" => size
      })
    end
  end
end
