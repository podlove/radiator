defmodule Radiator.Tracking do
  @moduledoc """
  The tracking context.
  """

  require Logger

  alias Radiator.Repo

  alias Radiator.Directory.{
    Podcast,
    Episode,
    AudioPublication
  }

  alias Radiator.Tracking.Download
  alias Radiator.Media.AudioFile

  @doc """
  Track Download

  Takes a list of parameters and converts them into a download event.

  ## Parameters

  - `file`: a `Radiator.Media.AudioFile`
  - `remote_ip`: request IP string
  - `user_agent`: raw user agent string from request
  - `time`: time of request
  - `http_range`: raw HTTP RANGE header from request

  """
  def track_download(params)

  def track_download(
        podcast: podcast = %Podcast{},
        episode: episode = %Episode{},
        audio_file: audio_file = %AudioFile{},
        remote_ip: remote_ip,
        user_agent: user_agent_string,
        time: time,
        http_range: http_range
      ) do
    audio_file = Repo.preload(audio_file, :audio)
    network = podcast.network
    user_agent = parse_user_agent(user_agent_string)

    if download_looks_clean(Map.get(user_agent, :bot), http_range) do
      %Download{}
      |> Download.changeset(%{
        request_id: request_id(remote_ip, user_agent_string),
        accessed_at: time,
        clean: true,
        http_range: http_range,
        user_agent: user_agent_string,
        client_name: Map.get(user_agent, :client_name),
        client_type: Map.get(user_agent, :client_type),
        device_model: Map.get(user_agent, :device_model),
        device_type: Map.get(user_agent, :device_type),
        os_name: Map.get(user_agent, :os_name),
        hours_since_published: hours_since_published(episode, time)
      })
      |> Ecto.Changeset.put_assoc(:network, network)
      |> Ecto.Changeset.put_assoc(:podcast, podcast)
      |> Ecto.Changeset.put_assoc(:episode, episode)
      |> Ecto.Changeset.put_assoc(:audio, audio_file.audio)
      |> Ecto.Changeset.put_assoc(:file, audio_file)
      |> Repo.insert()
    else
      {:ok, :skipped_because_not_clean}
    end
  end

  def track_download(
        audio_publication: audio_publication = %AudioPublication{},
        audio_file: audio_file = %AudioFile{},
        remote_ip: remote_ip,
        user_agent: user_agent_string,
        time: time,
        http_range: http_range
      ) do
    audio_file = Repo.preload(audio_file, :audio)
    network = audio_publication.network
    user_agent = parse_user_agent(user_agent_string)

    if download_looks_clean(Map.get(user_agent, :bot), http_range) do
      %Download{}
      |> Download.changeset(%{
        request_id: request_id(remote_ip, user_agent_string),
        accessed_at: time,
        clean: true,
        http_range: http_range,
        user_agent: user_agent_string,
        client_name: Map.get(user_agent, :client_name),
        client_type: Map.get(user_agent, :client_type),
        device_model: Map.get(user_agent, :device_model),
        device_type: Map.get(user_agent, :device_type),
        os_name: Map.get(user_agent, :os_name),
        hours_since_published: hours_since_published(audio_publication, time)
      })
      |> Ecto.Changeset.put_assoc(:network, network)
      |> Ecto.Changeset.put_assoc(:audio_publication, audio_publication)
      |> Ecto.Changeset.put_assoc(:audio, audio_file.audio)
      |> Ecto.Changeset.put_assoc(:file, audio_file)
      |> Repo.insert()
    else
      {:ok, :skipped_because_not_clean}
    end
  end

  def track_download(params) do
    Logger.warn(
      "[Tracking] Unable to track request given params. param keys: #{
        inspect(Keyword.keys(params))
      } params: #{inspect(params, pretty: true, limit: :infinity, printable_limit: :infinity)}"
    )
  end

  defp parse_user_agent(user_agent_string) do
    user_agent_string
    |> UAInspector.parse()
    |> case do
      %UAInspector.Result.Bot{name: bot_name} ->
        %{bot: true, client_name: to_ua_field(bot_name)}

      result = %UAInspector.Result{} ->
        %{
          bot: false,
          client_name: to_ua_field(result.client, :name),
          client_type: to_ua_field(result.client, :type),
          device_model: to_ua_field(result.device, :model),
          device_type: to_ua_field(result.device, :type),
          os_name: to_ua_field(result.os, :name)
        }
    end
  end

  @doc """
  Does the download request seem clean?

  Looks clean if it is not a bot and httprange is not "bytes=0-1" or "bytes=0-0".

  todo: I think it would be cleaner to implement these checks
        as custom changeset validations on Radiator.Tracking.Download
  """
  @spec download_looks_clean(boolean(), binary()) :: boolean()
  def download_looks_clean(bot?, http_range)
  def download_looks_clean(true, _), do: false
  def download_looks_clean(_, "bytes=0-1"), do: false
  def download_looks_clean(_, "bytes=0-0"), do: false
  def download_looks_clean(_, _), do: true

  defp to_ua_field(:unknown, _), do: nil

  defp to_ua_field(result_group, key) do
    to_ua_field(Map.get(result_group, key))
  end

  defp to_ua_field(:unknown), do: nil
  defp to_ua_field(value) when is_binary(value), do: value

  defp hours_since_published(episode = %Episode{}, time = %DateTime{}) do
    trunc(DateTime.diff(time, episode.published_at, :second) / 3600)
  end

  defp hours_since_published(audio_publication = %AudioPublication{}, time = %DateTime{}) do
    trunc(DateTime.diff(time, audio_publication.published_at, :second) / 3600)
  end

  defp request_id(remote_ip, user_agent) do
    :crypto.hash(:sha256, request_id_plain(remote_ip, user_agent))
    |> Base.encode64(padding: false)
    |> String.slice(0..7)
  end

  defp request_id_plain(remote_ip, user_agent) do
    remote_ip <> user_agent
  end

  @doc """
  Updates a download.

  ## Examples

      iex> update_download(download, %{field: new_value})
      {:ok, %Download{}}

      iex> update_download(download, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_download(%Download{} = download, attrs) do
    download
    |> Download.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Download.

  ## Examples

      iex> delete_download(download)
      {:ok, %Download{}}

      iex> delete_download(download)
      {:error, %Ecto.Changeset{}}

  """
  def delete_download(%Download{} = download) do
    Repo.delete(download)
  end
end
