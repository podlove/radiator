defmodule Radiator.Feeds.Feed.Channel do
  @moduledoc "The channel level of an RSS feed, in the feed's own vocabulary."
  defstruct [
    :title,
    :link,
    :description,
    :language,
    :copyright,
    :author,
    :subtitle,
    :summary,
    :funding_url,
    :funding_text,
    :license,
    :license_url,
    :owner_name,
    :owner_email,
    :image_url,
    :podcast_type,
    :explicit,
    :guid,
    categories: [],
    persons: []
  ]
end
