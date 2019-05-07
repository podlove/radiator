defmodule Radiator.Tracking do
  @moduledoc """
  The tracking context.
  """

  require Logger

  alias Radiator.Repo

  def process_access(
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

    ## todo: save to db and we have a basic tracking running
    :ok
  end
end
