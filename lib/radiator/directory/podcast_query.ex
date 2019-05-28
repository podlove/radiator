defmodule Radiator.Directory.PodcastQuery do
  import Ecto.Query, warn: false

  # alias Radiator.Directory.Podcast

  def filter_by_published(query) do
    filter_by_published(query, true)
  end

  def filter_by_published(query, true) do
    now = DateTime.utc_now()
    from(e in query, where: e.published_at <= ^now)
  end

  def filter_by_published(query, false) do
    now = DateTime.utc_now()
    from(e in query, where: e.published_at > ^now or is_nil(e.published_at))
  end

  def filter_by_published(query, :any) do
    query
  end
end
