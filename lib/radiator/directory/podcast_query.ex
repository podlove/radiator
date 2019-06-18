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

  def find_by_slug(query, slug) do
    slug = slug |> String.downcase()
    from(p in query, where: fragment("lower(?)", p.slug) == ^slug)
  end

  def find_by_short_id(query, short_id) do
    short_id = short_id |> String.downcase()
    from(p in query, where: fragment("lower(?)", p.short_id) == ^short_id)
  end
end
