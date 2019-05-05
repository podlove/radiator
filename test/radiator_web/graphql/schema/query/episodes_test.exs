defmodule RadiatorWeb.GraphQL.Schema.Query.EpisodesTest do
  use RadiatorWeb.ConnCase, async: true
  import Radiator.Factory

  @single_query """
  query ($id: ID!) {
    episode(id: $id) {
      id
      title
    }
  }
  """

  test "episode returns an episode", %{conn: conn} do
    podcast = insert(:podcast)
    episode = insert(:episode, podcast: podcast)

    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => episode.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "episode" => %{"id" => Integer.to_string(episode.id), "title" => episode.title}
             }
           }
  end

  test "episode returns an error when queried with a non-existent ID", %{conn: conn} do
    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => -1}
    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Episode ID -1 not found"
  end

  @is_published_query """
  query ($id: ID!) {
    episode(id: $id) {
      id
      isPublished
    }
  }
  """

  describe "is_published" do
    test "is false for an unpublished episode", %{conn: conn} do
      episode = insert(:episode)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => episode.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "episode" => %{"id" => Integer.to_string(episode.id), "isPublished" => false}
               }
             }
    end

    test "is true for a published episode", %{conn: conn} do
      episode = insert(:episode, published_at: DateTime.utc_now())

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => episode.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "episode" => %{"id" => Integer.to_string(episode.id), "isPublished" => true}
               }
             }
    end

    test "is false for published_at dates in the future", %{conn: conn} do
      in_one_hour = DateTime.utc_now() |> DateTime.add(3600)
      episode = insert(:episode, published_at: in_one_hour)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => episode.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "episode" => %{"id" => Integer.to_string(episode.id), "isPublished" => false}
               }
             }
    end
  end
end
