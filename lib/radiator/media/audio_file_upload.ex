defmodule Radiator.Media.AudioFileUpload do
  @moduledoc """
  Upload AudioFile files.

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
    iex> {:ok, audio} = Radiator.Media.AudioFileUpload.upload(upload)

  """
  alias Ecto.Multi
  alias Radiator.Repo
  alias Radiator.Media.Audio

  @spec upload(Plug.Upload.t()) :: {:ok, Radiator.Media.AudioFile.t()} | {:error, atom()}
  def upload(upload = %Plug.Upload{}) do
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
    fn %{create_audio: audio} ->
      Audio.changeset(audio, %{
        "title" => upload.filename,
        "file" => upload
      })
    end
  end
end
