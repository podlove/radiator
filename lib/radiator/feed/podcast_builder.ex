defmodule Radiator.Feed.PodcastBuilder do
  import XmlBuilder
  import Radiator.Feed.Builder, only: [add: 2]
  import Radiator.Feed.Guards

  alias Radiator.Directory.Podcast
  alias Radiator.Feed.EpisodeBuilder
  alias Radiator.Feed.PagingMeta

  @doc """
  See `Radiator.Feed.Builder.new/2` for parameter docs.
  """
  def new(feed_data, opts \\ []) do
    opts = opts ++ [paging: PagingMeta.build(feed_data, opts)]

    element(:channel, fields(feed_data, opts))
  end

  defp fields(feed_data = %{podcast: podcast}, opts) do
    []
    |> add(element(:title, podcast.title))
    |> add(subtitle(podcast))
    |> add(description(podcast))
    |> add(element(:generator, "Podlove Radiator"))
    |> add(self_reference(feed_data))
    # |> add(last_build_date())
    |> Enum.reverse()
    |> Enum.concat(paging_elements(feed_data, opts))
    |> Enum.concat(episode_items(feed_data, opts))
  end

  defp self_reference(%{podcast: podcast, urls: %{self: self}}) do
    element("atom:link", %{
      rel: "self",
      type: "application/rss+xml",
      title: podcast.title,
      href: self
    })
  end

  defp self_reference(_), do: nil

  defp paging_elements(_feed_data, opts) do
    []
    |> add(first_page_link(opts[:paging].first_page_url))
    |> add(last_page_link(opts[:paging].last_page_url))
    |> add(next_page_link(opts[:paging].next_page_url))
    |> add(prev_page_link(opts[:paging].prev_page_url))
    |> Enum.reverse()
  end

  defp first_page_link(url) when is_binary(url) do
    element("atom:link", %{rel: "first", href: url})
  end

  defp first_page_link(_) do
    nil
  end

  defp last_page_link(url) when is_binary(url) do
    element("atom:link", %{rel: "last", href: url})
  end

  defp last_page_link(_) do
    nil
  end

  defp next_page_link(url) when is_binary(url) do
    element("atom:link", %{rel: "next", href: url})
  end

  defp next_page_link(_) do
    nil
  end

  defp prev_page_link(url) when is_binary(url) do
    element("atom:link", %{rel: "prev", href: url})
  end

  defp prev_page_link(_) do
    nil
  end

  defp episode_items(feed_data = %{episodes: episodes}, opts) do
    with start_index <- (opts[:paging].current_page - 1) * opts[:paging].total_pages do
      episodes
      |> Enum.slice(start_index, opts[:items_per_page])
      |> Enum.map(fn episode ->
        EpisodeBuilder.new(feed_data, episode)
      end)
    end
  end

  defp subtitle(%Podcast{subtitle: subtitle}) when set?(subtitle),
    do: element("itunes:subtitle", subtitle)

  defp subtitle(_), do: nil

  defp description(%Podcast{description: description}) when set?(description),
    do: element(:description, description)

  defp description(_), do: nil
end
