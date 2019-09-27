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
      iex> {:ok, audio_file} = Radiator.Media.AudioFileUpload.upload(upload, audio)

  """
  alias Ecto.Multi
  alias Radiator.Repo
  alias Radiator.Media.AudioFile
  alias Radiator.Directory.Audio

  require Logger

  @doc """
  Upload audio file and attach it to audio object.

  `upload` parameter can be anything that the arc `store` function accepts, see https://github.com/stavro/arc#basics
  """
  @spec upload(any(), Audio.t()) :: {:ok, AudioFile.t()} | {:error, :failed}
  def upload(upload, audio = %Audio{}) do
    Logger.info("upload: #{inspect(upload)} audio: #{inspect(audio)}")

    Multi.new()
    |> Multi.insert(:create_audio_file, create_audio_file_changeset(audio))
    |> Multi.update(:audio_file, add_audio_file_changeset(upload))
    |> Multi.update(:audio, fn %{audio_file: audio_file} ->
      %Audio{id: audio.id}
      |> Audio.changeset(%{duration: audio_file.duration})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{audio_file: audio_file}} ->
        {:ok, audio_file}

      {:error, _, _, _} = error ->
        Logger.debug("Upload failure: #{inspect(error, pretty: true)}")
        {:error, :failed}
    end
  end

  defp create_audio_file_changeset(audio) do
    AudioFile.changeset(%AudioFile{}, %{audio_id: audio.id})
  end

  defp add_audio_file_changeset(upload = %Plug.Upload{path: path, filename: filename})
       when is_binary(path) and is_binary(filename) do
    {:ok, %File.Stat{size: size}} = File.lstat(path)
    mime_type = MIME.from_path(path) |> fix_mime_type()

    attrs = %{
      "title" => filename,
      "file" => upload,
      "mime_type" => mime_type,
      "byte_length" => size,
      # some rough approximated default
      "duration" => ceil(size / 96)
    }

    attrs =
      case probe_file(path) do
        {:ok, additional_attrs} ->
          Logger.info("additional attributes: #{inspect(additional_attrs)}")

          attrs
          |> Map.merge(additional_attrs)

        stuff ->
          attrs
      end

    fn %{create_audio_file: audio_file} ->
      AudioFile.changeset(audio_file, attrs)
    end
  end

  defp parse_k(string, suffix) when is_binary(string) do
    case Float.parse(string) do
      {float, _rest} ->
        "#{float / 1_000.0}" <> suffix

      _ ->
        string
    end
  end

  def probe_file(path) do
    with {:ok, streams} <- FFprobe.streams(path) do
      stream =
        streams
        |> Enum.find(hd(streams), fn m -> m["codec_type"] == "audio" end)

      duration = ((Float.parse(stream["duration"]) |> elem(0)) * 1_000) |> ceil

      audio_format =
        ["codec_long_name", "bit_rate", "sample_rate"]
        |> Enum.map(fn key -> {key, stream[key]} end)
        |> Enum.reduce([], fn
          {_, nil}, acc ->
            acc

          {"bit_rate", value}, acc ->
            [parse_k(value, "kbps") | acc]

          {"sample_rate", value}, acc ->
            [parse_k(value, "kHz") | acc]

          {_, value}, acc ->
            [value | acc]
        end)
        |> Enum.reverse()
        |> Enum.join(", ")

      {:ok,
       %{
         "duration" => duration,
         "audio_format" => audio_format
       }}
    end
  end

  defp fix_mime_type("application/octet-stream"), do: "audio/mpeg"
  defp fix_mime_type(mime), do: mime

  # Need to download first, otherwise the database transaction is not having fun and timing out
  def sideload(url, audio = %Audio{}) do
    uri = URI.parse(url)
    filename = Path.basename(uri.path)

    case save_file(uri, filename) do
      {:ok, local_path} ->
        upload(
          %Plug.Upload{
            filename: filename,
            path: local_path
          },
          audio
        )

        File.rm(local_path)

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

  require Logger

  # hakney :connect_timeout - timeout used when establishing a connection, in milliseconds
  # hakney :recv_timeout - timeout used when receiving from a connection, in milliseconds
  # poison :timeout - timeout to establish a connection, in milliseconds
  # :backoff_max - maximum backoff time, in milliseconds
  # :backoff_factor - a backoff factor to apply between attempts, in milliseconds
  defp get_remote_path(remote_path) do
    Logger.debug("get remote: #{remote_path}")

    options = [
      follow_redirect: true,
      recv_timeout: Application.get_env(:arc, :recv_timeout, 5_000),
      connect_timeout: Application.get_env(:arc, :connect_timeout, 10_000),
      timeout: Application.get_env(:arc, :timeout, 10_000),
      max_retries: Application.get_env(:arc, :max_retries, 3),
      backoff_factor: Application.get_env(:arc, :backoff_factor, 1000),
      backoff_max: Application.get_env(:arc, :backoff_max, 30_000),

      # disable cert verification for sideloading for now, as we got spurious {bad_cert,invalid_key_usage}
      ssl_options: [verify: :verify_none]
    ]

    request(remote_path, options)
  end

  defp request_headers do
    # TODO: unify with metalove
    [{"User-Agent", "RadiatorImportBot/1.0 (https://github.com/podlove/radiator)"}]
  end

  defp request(remote_path, options, tries \\ 0) do
    case :hackney.get(URI.to_string(remote_path), request_headers(), "", options) do
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
