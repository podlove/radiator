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

  @doc """
  Generate all feeds for a podcast.
  """
  @spec generate(integer(), any()) :: [{:ok, binary(), [binary()]}]
  def generate(podcast_id, opts \\ []) do
    Radiator.Feed.Storage.types()
    |> Enum.map(&to_string/1)
    |> Enum.map(fn type -> {:ok, type, generate(podcast_id, type, opts)} end)
  end

  @doc """
  Generate feed XML for podcast and given type.

  Returns a list, one entry per feed page.
  """
  @spec generate(integer(), binary(), any()) :: [binary()]
  def generate(podcast_id, type, opts) do
    opts =
      opts
      |> Keyword.put_new(:items_per_page, 25)

    with podcast <- Editor.Editor.get_podcast(podcast_id),
         episodes <- fetch_episodes(podcast) do
      feed_url = Podcast.feed_url(podcast, type)
      page_count = ceil(length(episodes) / opts[:items_per_page])

      # fixme: handle page_count == 0

      1..page_count
      |> Enum.map(fn page ->
        Builder.new(
          %{
            # TODO: think about confusion between slots and types -- maybe unify? Or at least a better API around it.
            type: get_slot(type),
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

  defp get_slot("mp3"), do: "audio_mp3"
  defp get_slot("m4a"), do: "audio_m4a"
  defp get_slot("ogg"), do: "audio_ogg"
  defp get_slot("opus"), do: "audio_opus"

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
