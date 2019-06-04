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

  defp add_audio_file_changeset(upload) when is_binary(upload) do
    mime_type = MIME.from_path(upload)

    # todo: get byte_length _after_ storing

    fn %{create_audio: audio} ->
      AudioFile.changeset(audio, %{
        # "title" => filename,
        "file" => upload,
        "mime_type" => mime_type
        # "byte_length" => size
      })
    end
  end

  # Need to download first, otherwise the database transaction is not having fun and timing out
  def sideload(url, episode = %Episode{}) do
    uri = URI.parse(url)
    filename = Path.basename(uri.path)

    case save_file(uri, filename) do
      {:ok, local_path} ->
        upload(
          %Plug.Upload{
            filename: filename,
            path: local_path
          },
          episode
        )

      _ ->
        {:error, :download_failed}
    end
  end

  defp save_file(uri, filename) do
    local_path =
      generate_temporary_path()
      |> Kernel.<>(Path.extname(filename))

    case save_temp_file(local_path, uri) do
      :ok -> {:ok, local_path}
      _ -> :error
    end
  end

  defp save_temp_file(local_path, remote_path) do
    remote_file = get_remote_path(remote_path)

    case remote_file do
      {:ok, body} -> File.write(local_path, body)
      {:error, error} -> {:error, error}
    end
  end

  # hakney :connect_timeout - timeout used when establishing a connection, in milliseconds
  # hakney :recv_timeout - timeout used when receiving from a connection, in milliseconds
  # poison :timeout - timeout to establish a connection, in milliseconds
  # :backoff_max - maximum backoff time, in milliseconds
  # :backoff_factor - a backoff factor to apply between attempts, in milliseconds
  defp get_remote_path(remote_path) do
    options = [
      follow_redirect: true,
      recv_timeout: Application.get_env(:arc, :recv_timeout, 5_000),
      connect_timeout: Application.get_env(:arc, :connect_timeout, 10_000),
      timeout: Application.get_env(:arc, :timeout, 10_000),
      max_retries: Application.get_env(:arc, :max_retries, 3),
      backoff_factor: Application.get_env(:arc, :backoff_factor, 1000),
      backoff_max: Application.get_env(:arc, :backoff_max, 30_000)
    ]

    request(remote_path, options)
  end

  defp request(remote_path, options, tries \\ 0) do
    case :hackney.get(URI.to_string(remote_path), [], "", options) do
      {:ok, 200, _headers, client_ref} ->
        :hackney.body(client_ref)

      {:error, %{reason: :timeout}} ->
        case retry(tries, options) do
          {:ok, :retry} -> request(remote_path, options, tries + 1)
          {:error, :out_of_tries} -> {:error, :timeout}
        end

      _ ->
        {:error, :arc_httpoison_error}
    end
  end

  defp retry(tries, options) do
    cond do
      tries < options[:max_retries] ->
        backoff = round(options[:backoff_factor] * :math.pow(2, tries - 1))
        backoff = :erlang.min(backoff, options[:backoff_max])
        :timer.sleep(backoff)
        {:ok, :retry}

      true ->
        {:error, :out_of_tries}
    end
  end

  def generate_temporary_path(file \\ nil) do
    extension = Path.extname((file && file.path) || "")

    file_name =
      :crypto.strong_rand_bytes(20)
      |> Base.encode32()
      |> Kernel.<>(extension)

    Path.join(System.tmp_dir(), file_name)
  end
end
