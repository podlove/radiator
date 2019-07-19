defmodule RadiatorWeb.GraphQL.Public.Schema.Query.NetworksTest do
  use RadiatorWeb.ConnCase, async: true
  import Radiator.Factory

  @single_query """
  query ($id: ID!) {
    publishedNetwork(id: $id) {
      id
      title
    }
  }
  """

  test "network returns a network", %{conn: conn} do
    network = insert(:network)

    insert(:podcast, network: network)

    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => network.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "publishedNetwork" => %{
                 "id" => Integer.to_string(network.id),
                 "title" => network.title
               }
             }
           }
  end

  test "network returns an error when queried with a non-existent ID", %{conn: conn} do
    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => -1}
    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Network ID -1 not found"
  end

  @single_query_with_podcasts """
  query ($id: ID!) {
    publishedNetwork(id: $id) {
      id
      title
      podcasts {
        title
      }
    }
  }
  """

  test "network has embedded published podcasts", %{conn: conn} do
    network = insert(:network)
    podcast_1 = insert(:podcast, network: network)
    podcast_2 = insert(:podcast, network: network)
    _podcast_3 = insert(:unpublished_podcast, network: network)
    insert(:podcast)

    conn =
      get conn, "/api/graphql",
        query: @single_query_with_podcasts,
        variables: %{"id" => network.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "publishedNetwork" => %{
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

  @list_query """
    {
      publishedNetworks {
        id
        title
      }
    }
  """

  test "networks returns list of networks", %{conn: conn} do
    network = insert(:network)
    insert(:podcast, network: network)

    conn = get conn, "/api/graphql", query: @list_query

    assert json_response(conn, 200) == %{
             "data" => %{
               "publishedNetworks" => [
                 %{
                   "id" => Integer.to_string(network.id),
                   "title" => network.title
                 }
               ]
             }
           }
  end
end
