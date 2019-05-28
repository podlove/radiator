defmodule RadiatorWeb.GraphQL.Public.Schema.Query.PodcastsTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  @list_query """
  {
    podcasts {
      id
      title
    }
  }
  """

  test "podcasts returns a list of published podcasts", %{conn: conn} do
    podcasts = insert_list(3, :podcast)
    _podcast = insert(:unpublished_podcast)

    conn = get conn, "/api/graphql", query: @list_query

    assert json_response(conn, 200) == %{
             "data" => %{
               "podcasts" =>
                 Enum.map(podcasts, &%{"id" => Integer.to_string(&1.id), "title" => &1.title})
             }
           }
  end

  @single_query """
  query ($id: ID!) {
    podcast(id: $id) {
      id
      title
    }
  }
  """

  test "podcast returns a podcast", %{conn: conn} do
    podcast = insert(:podcast)
    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => podcast.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "podcast" => %{"id" => Integer.to_string(podcast.id), "title" => podcast.title}
             }
           }
  end

  test "podcast returns an error when queried with a non-existent ID", %{conn: conn} do
    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => -1}
    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Podcast ID -1 not found"
  end

  test "podcast returns an error if not published", %{conn: conn} do
    podcast = insert(:unpublished_podcast)
    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => podcast.id}

    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Podcast ID #{podcast.id} not found"
  end

  describe "episodes" do
    @with_episodes_query """
    query ($id: ID!) {
      podcast(id: $id) {
        id
        episodes {
          id
          title
        }
      }
    }
    """

    test "returns all published episodes of a podcast", %{conn: conn} do
      podcast = insert(:podcast)
      episode = insert(:published_episode, podcast: podcast)
      _episode = insert(:unpublished_episode, podcast: podcast)

      conn =
        get conn, "/api/graphql", query: @with_episodes_query, variables: %{"id" => podcast.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "podcast" => %{
                   "id" => Integer.to_string(podcast.id),
                   "episodes" => [
                     %{"id" => Integer.to_string(episode.id), "title" => episode.title}
                   ]
                 }
               }
             }
    end
  end

  describe "episodes_count" do
    @with_episodes_count_query """
    query ($id: ID!) {
      podcast(id: $id) {
        id
        episodesCount
      }
    }
    """

    test "returns the number of published episodes associated to a podcast", %{conn: conn} do
      podcast = insert(:podcast)
      _episode1 = insert(:published_episode, podcast: podcast)
      _episode2 = insert(:published_episode, podcast: podcast)
      _episode3 = insert(:unpublished_episode, podcast: podcast)

      conn =
        get conn, "/api/graphql",
          query: @with_episodes_count_query,
          variables: %{"id" => podcast.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "podcast" => %{"id" => Integer.to_string(podcast.id), "episodesCount" => 2}
               }
             }
    end
  end
end
