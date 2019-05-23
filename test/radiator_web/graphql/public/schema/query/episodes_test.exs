defmodule RadiatorWeb.GraphQL.Public.Schema.Query.EpisodesTest do
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
    episode = insert(:published_episode, podcast: podcast)

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

  test "episode returns an error if not published", %{conn: conn} do
    episode = insert(:unpublished_episode)

    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => episode.id}

    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Episode ID #{episode.id} not found"
  end
end
