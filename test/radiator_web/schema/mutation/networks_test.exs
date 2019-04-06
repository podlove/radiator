defmodule RadiatorWeb.Schema.Mutation.NetworksTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  @create_query """
  mutation ($network: NetworkInput!) {
    createNetwork(network: $network) {
      id
      title
    }
  }
  """

  test "createNetwork creates a network", %{conn: conn} do
    network = params_for(:network)

    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"network" => network}

    title = network.title

    assert %{
             "data" => %{
               "createNetwork" => %{
                 "title" => ^title,
                 "id" => id
               }
             }
           } = json_response(conn, 200)

    refute is_nil(id)
  end

  test "createNetwork returns error when missing data", %{conn: conn} do
    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"network" => %{}}

    assert %{
             "errors" => [
               %{
                 "message" => msg
               }
             ]
           } = json_response(conn, 200)

    assert msg =~ ~r/Argument "network" has invalid value \$network/
  end
end
