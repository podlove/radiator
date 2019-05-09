defmodule Radiator.Tracking do
  @moduledoc """
  The tracking context.
  """

  require Logger

  alias Radiator.Repo
  alias Radiator.Tracking.Download

  def track_download(
        file: file,
        request_id: request_id,
        user_agent: user_agent,
        time: time,
        http_range: http_range
      ) do
    file = Repo.preload(file, episode: [podcast: :network])
    episode = file.episode
    podcast = episode.podcast
    network = podcast.network

    # create download
    %Download{}
    |> Download.changeset(%{
      request_id: request_id,
      accessed_at: time,
      clean: true,
      http_range: http_range,
      user_agent: user_agent
    })
    |> Ecto.Changeset.put_assoc(:network, network)
    |> Ecto.Changeset.put_assoc(:podcast, podcast)
    |> Ecto.Changeset.put_assoc(:episode, episode)
    |> Repo.insert()
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
