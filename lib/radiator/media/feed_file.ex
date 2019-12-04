defmodule Radiator.Media.FeedFile do
  use Arc.Definition

  def filename(_version, {_file, [podcast_id: _podcast_id, type: _type, page: 1]}) do
    "feed.xml"
  end

  def filename(_version, {_file, [podcast_id: _podcast_id, type: _type, page: page]}) do
    "feed_page_#{page}.xml"
  end

  def storage_dir(_version, {_file, [podcast_id: podcast_id, type: type, page: _page]}) do
    "feed/#{podcast_id}/#{type}"
  end

  def s3_object_headers(_version, {_file, _scope}) do
    [content_type: "text/xml"]
  end
end
