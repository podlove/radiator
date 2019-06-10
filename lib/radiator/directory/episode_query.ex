defmodule Radiator.Directory.EpisodeQuery do
  @moduledoc """
  Builds Ecto query to list episodes.

  ## Arguments

  * `:published` - which publication state should be included
    * `true` - only published episodes are included
    * `false` - only unpublished episodes are included
    * `:any` - no filter is applied

  * `:podcast` - only include episodes belonging to given podcast

  **Ordering**

  * `:order_by` - Sort retrieved episodes by parameter.
    * `:title` - sort by episode title
    * `:published_at` - sort by episode publication date
    * `:number` - sort by episode number

  * `:order` -  Designates the ascending or descending order of the `:order_by` parameter. Default: `:desc`
    * `:asc` - ascending order from lowest to highest values (1, 2, 3; a, b, c).
    * `:desc` - descending order from highest to lowest values (3, 2, 1; c, b, a).

  **Pagination**

  * `:items_per_page` - number of episodes to show per page. Use `:unlimited` to remove pagination. Default: 10

  * `:page` - page number. Has no effect if `:items_per_page` is `:unlimited`. Default: 1

  ## Examples

      iex> Radiator.Directory.EpisodeQuery.build(%{published: true, order_by: :published_at, order: :desc})
      #Ecto.Query<from e0 in Radiator.Directory.Episode, ...>

      iex> Radiator.Directory.EpisodeQuery.build(%{})
      Radiator.Directory.Episode
  """
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

  def build(args) when is_map(args) do
    pagination_args = Map.take(args, [:items_per_page, :page])

    Enum.reduce(args, Episode, fn
      {:published, published}, query ->
        filter_by_published(query, published)

      {:podcast, podcast}, query ->
        filter_by_podcast(query, podcast)

      {:order_by, order_by}, query ->
        direction = Map.get(args, :order, :desc)
        order(query, order_by, direction)

      {:order, _}, query ->
        query

      {:items_per_page, _}, query ->
        paginate(query, pagination_args)

      {:page, _}, query ->
        paginate(query, pagination_args)
    end)
  end

  def filter_by_podcast(query, %Podcast{} = podcast) do
    from(e in query, where: e.podcast_id == ^podcast.id)
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

  def order(query, order, direction) when direction in [:asc, :desc] do
    order_by = [{direction, order}]
    from(e in query, order_by: ^order_by)
  end

  @default_items_per_page 10

  def paginate(query, %{items_per_page: :unlimited}) do
    query
  end

  def paginate(query, %{items_per_page: items_per_page, page: page})
      when is_integer(items_per_page) and is_integer(page) do
    offset = items_per_page * (page - 1)
    from(e in query, limit: ^items_per_page, offset: ^offset)
  end

  def paginate(query, %{page: page}) when is_integer(page) do
    paginate(query, %{items_per_page: @default_items_per_page, page: page})
  end

  def paginate(query, %{items_per_page: items_per_page}) when is_integer(items_per_page) do
    paginate(query, %{items_per_page: items_per_page, page: 1})
  end

  def paginate(query, _) do
    paginate(query, %{items_per_page: @default_items_per_page, page: 1})
  end
end
