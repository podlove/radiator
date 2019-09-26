defmodule Radiator.Directory.EpisodeQuery do
  @moduledoc """
  Builds Ecto query to list episodes.

  ## Arguments

  * `:published` - which publication state should be included
    * `true` - only published episodes are included
    * `false` - only unpublished episodes are included
    * `:any` - no filter is applied

  * `:podcast` - only include episodes belonging to given podcast

  * `:slug` - find the episode with a given slug

  * `:short_id` - filter episodes by short_id

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

      {:slug, slug}, query ->
        find_by_slug(query, slug)

      {:short_id, short_id}, query ->
        filter_by_short_id(query, short_id)

      {:include_downloads, true}, query ->
        include_downloads(query)

      {:include_downloads, _}, query ->
        query
    end)
    # force preloading of podcast for now as we need it most of the time anyways
    |> preload([e], [:podcast])
  end

  def include_downloads(query) do
    from(e in query,
      left_join: r in Radiator.Reporting.Report,
      on: r.subject_type == "episode" and r.time_type == "total" and r.subject == e.id,
      select_merge: %{downloads_total: r.downloads}
    )
  end

  def filter_by_podcast(query, podcast_id) when is_integer(podcast_id) do
    from(e in query, where: e.podcast_id == ^podcast_id)
  end

  def filter_by_podcast(query, %Podcast{} = podcast) do
    filter_by_podcast(query, podcast.id)
  end

  def filter_by_published(query, true) do
    from(e in query, where: e.publish_state == "published")
  end

  def filter_by_published(query, false) do
    from(e in query, where: e.publish_state != "published")
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

  def find_by_slug(query, slug) do
    slug = slug |> String.downcase()
    from(e in query, where: fragment("lower(?)", e.slug) == ^slug)
  end

  def filter_by_short_id(query, short_id) do
    short_id = short_id |> String.downcase()
    from(e in query, where: fragment("lower(?)", e.short_id) == ^short_id)
  end
end
