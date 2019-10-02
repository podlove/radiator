defmodule Radiator.Feed.Generator do
  @moduledoc """
  RSS Feed Generator.

  Generates list of XML documents (one per feed page) for given podcast id.
  """

  alias Radiator.Feed.Builder
  alias Radiator.Directory

  alias Radiator.Directory.{
    Editor,
    Podcast
  }

  def generate(podcast_id, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:items_per_page, 25)

    with podcast <- Editor.Editor.get_podcast(podcast_id),
         episodes <- fetch_episodes(podcast) do
      # TODO: there will be multiple feeds per podcast
      feed_url = Podcast.feed_url(podcast)
      page_count = ceil(length(episodes) / opts[:items_per_page])

      1..page_count
      |> Enum.map(fn page ->
        Builder.new(
          %{
            podcast: podcast,
            episodes: episodes,
            urls: %{
              main: feed_url,
              self: feed_url,
              page_template: page_url_template(feed_url)
            }
          },
          items_per_page: opts[:items_per_page],
          page: page
        )
        |> Builder.render()
      end)
    end
  end

  def fetch_episodes(podcast = %Podcast{}) do
    %{podcast: podcast, order_by: :published_at, order: :desc}
    |> Directory.list_episodes()
    |> Directory.reject_invalid_episodes()
  end

  defp page_url_template(feed_url) do
    feed_url
    |> URI.parse()
    |> Map.put(:query, "page=:page:")
    |> URI.to_string()
  end
end
