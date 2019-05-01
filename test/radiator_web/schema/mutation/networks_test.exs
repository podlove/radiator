defmodule RadiatorWeb.Schema.Mutation.NetworksTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  alias Radiator.Directory
  alias Radiator.Media

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

  @update_query """
  mutation ($id: ID!, $network: NetworkInput!) {
    updateNetwork(id: $id, network: $network) {
      id
      title
    }
  }
  """

  test "updateNetwork updates a network", %{conn: conn} do
    network = insert(:network)

    upload = %Plug.Upload{
      path: "test/fixtures/image.jpg",
      filename: "image.jpg"
    }

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{
          network: %{title: "Meta meta!", image: "myupload"},
          id: network.id
        },
        myupload: upload

    id = Integer.to_string(network.id)

    assert %{
             "data" => %{
               "updateNetwork" => %{
                 "title" => "Meta meta!",
                 "id" => ^id
               }
             }
           } = json_response(conn, 200)

    network = Directory.get_network(id)
    assert Media.NetworkImage.url({network.image, network})
  end

  test "updateNetwork returns errors on missing values", %{conn: conn} do
    network = insert(:network)

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"network" => %{title: ""}, "id" => network.id}

    assert %{"errors" => [%{"message" => msg}]} = json_response(conn, 200)
    assert msg == "title can't be blank"
  end
end
