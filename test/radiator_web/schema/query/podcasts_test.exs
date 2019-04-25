defmodule RadiatorWeb.EpisodeControllerTest.Schema.Query.PodcastsTest do
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

  test "podcasts returns a list of podcasts", %{conn: conn} do
    podcasts = insert_list(3, :podcast)
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

  @is_published_query """
  query ($id: ID!) {
    podcast(id: $id) {
      id
      isPublished
    }
  }
  """

  describe "is_published" do
    test "is false for an unpublished podcast", %{conn: conn} do
      podcast = insert(:podcast)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => podcast.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "podcast" => %{"id" => Integer.to_string(podcast.id), "isPublished" => false}
               }
             }
    end

    test "is true for a published podcast", %{conn: conn} do
      podcast = insert(:podcast, published_at: DateTime.utc_now())

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => podcast.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "podcast" => %{"id" => Integer.to_string(podcast.id), "isPublished" => true}
               }
             }
    end

    test "is false for published_at dates in the future", %{conn: conn} do
      in_one_hour = DateTime.utc_now() |> DateTime.add(3600)
      podcast = insert(:podcast, published_at: in_one_hour)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => podcast.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "podcast" => %{"id" => Integer.to_string(podcast.id), "isPublished" => false}
               }
             }
    end
  end
end
