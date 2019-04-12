defmodule Radiator.Directory.EpisodeQuery do
  import Ecto.Query, warn: false

  alias Radiator.Directory.{Episode, Podcast}

  # TODO use an input object for pagination
  # FIXME pagination is broken for nested documents.
  #
  #   I am not sure how limit/paginate properly in nested documents.
  #
  #   {
  #     podcasts {
  #       title
  #       episodes(itemsPerPage: 1) {
  #         title
  #       }
  #     }
  #   }
  #
  #  What I want here is one episode per podcast but I only get one in total due to
  #  the way the SQL query is built.
  #  Is there even a way to build an SQL query for that? Do I have to fetch all and
  #  paginate in memory?
  #
  #  Also, it seems there are differnt pagination recommendations in graphql,
  #  see https://graphql.org/learn/pagination/

  def build(args) do
    pagination_args = Map.take(args, [:items_per_page, :page])

    Enum.reduce(args, Episode, fn
      {:published, published}, query ->
        filter_by_published(query, published)

      {:podcast, podcast}, query ->
        filter_by_podcast(query, podcast)

      {:order_by, order}, query ->
        order(query, order)

      {:items_per_page, _}, query ->
        paginate(query, pagination_args)

      {:page, _}, query ->
        paginate(query, pagination_args)
    end)
  end

  defp filter_by_podcast(query, %Podcast{} = podcast) do
    from(e in query, where: e.podcast_id == ^podcast.id)
  end

  defp filter_by_published(query, true) do
    from(e in query, where: e.published_at <= fragment("NOW()"))
  end

  defp filter_by_published(query, false) do
    from(e in query, where: e.published_at > fragment("NOW()") or is_nil(e.published_at))
  end

  defp filter_by_published(query, :any) do
    query
  end

  defp order(query, order) do
    from(e in query, order_by: ^order)
  end

  @default_items_per_page 10

  defp paginate(query, %{items_per_page: items_per_page, page: page})
       when is_integer(items_per_page) and is_integer(page) do
    offset = items_per_page * (page - 1)
    from(e in query, limit: ^items_per_page, offset: ^offset)
  end

  defp paginate(query, %{page: page}) when is_integer(page) do
    paginate(query, %{items_per_page: @default_items_per_page, page: page})
  end

  defp paginate(query, %{items_per_page: items_per_page}) when is_integer(items_per_page) do
    paginate(query, %{items_per_page: items_per_page, page: 1})
  end

  defp paginate(query, _) do
    query
  end
end
