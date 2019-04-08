defmodule Radiator.Feed.Builder do
  @moduledoc """
  RSS Feed Builder.
  """
  import XmlBuilder

  alias Radiator.Feed.PodcastBuilder

  @doc """
  Create RSS Document

  First `feed_data` argzment is a map containing the podcast, a list
  of all episodes and url values.

    %{
      podcast: %Radiator.Directory.Podcast{},
      episodes: [%Radiator.Directory.Episode{}],
      urls: %{
        main: "...",
        self: "...",
        page_template: "..."
      }
    }

  The second argument `opts`  is an optional keyword list. Supported options:

  - `items_per_page`: How many episodes per feed page? Default: no limit
  - `page`: What page number? Starts at 1. Default: 1
  """
  @spec new(map(), list()) :: tuple()
  def new(feed_data, opts \\ []) do
    element(:rss, rss_attributes(), [PodcastBuilder.new(feed_data, opts)])
  end

  def render(xml) do
    xml
    |> document()
    |> generate(format: :indent)
  end

  @doc """
  Add node to a list unless it is nil.
  """
  def add(list, nil), do: list
  def add(list, node), do: [node | list]

  defp rss_attributes() do
    %{
      version: "2.0",
      "xmlns:atom": "http://www.w3.org/2005/Atom",
      "xmlns:itunes": "http://www.itunes.com/dtds/podcast-1.0.dtd",
      "xmlns:content": "http://purl.org/rss/1.0/modules/content/",
      "xmlns:psc": "http://podlove.org/simple-chapters"
    }
  end
end
