defmodule RadiatorWeb.Schema.Query.NetworksTest do
  use RadiatorWeb.ConnCase, async: true
  import Radiator.Factory

  @single_query """
  query ($id: ID!) {
    network(id: $id) {
      id
      title
    }
  }
  """

  test "network returns a network", %{conn: conn} do
    network = insert(:network)

    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => network.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "network" => %{
                 "id" => Integer.to_string(network.id),
                 "title" => network.title
               }
             }
           }
  end

  test "network returns an error when queried with a non-existant ID", %{conn: conn} do
    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => -1}
    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Network ID -1 not found"
  end

  @single_query_with_podcasts """
  query ($id: ID!) {
    network(id: $id) {
      id
      title
      podcasts {
        title
      }
    }
  }
  """

  test "network has embedded podcasts", %{conn: conn} do
    network = insert(:network)
    podcast_1 = insert(:podcast, network: network)
    podcast_2 = insert(:podcast, network: network)
    insert(:podcast)

    conn =
      get conn, "/api/graphql",
        query: @single_query_with_podcasts,
        variables: %{"id" => network.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "network" => %{
                 "id" => Integer.to_string(network.id),
                 "title" => network.title,
                 "podcasts" => [
                   %{"title" => podcast_1.title},
                   %{"title" => podcast_2.title}
                 ]
               }
             }
           }
  end
end
