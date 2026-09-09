defmodule Radiator.Feeds.Feed.Item do
  @moduledoc "An `<item>` of an RSS feed, in the feed's own vocabulary."
  defstruct [
    :guid,
    :title,
    :itunes_title,
    :link,
    :description,
    :content_html,
    :subtitle,
    :itunes_summary,
    :author,
    :chapters_url,
    :chapters_type,
    :published_at,
    :duration_seconds,
    :number,
    :season,
    :episode_type,
    :image_url,
    :enclosure,
    chapters: [],
    transcripts: [],
    persons: []
  ]
end
