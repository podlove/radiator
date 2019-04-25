defmodule RadiatorWeb.Schema.Mutation.NetworksTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  @create_query """
  mutation ($network: NetworkInput!) {
    createNetwork(network: $network) {
      id
      title
      slug
    }
  }
  """

  test "createNetwork creates a network", %{conn: conn} do
    conn = Radiator.TestEntries.put_authenticated_user(conn)

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

  test "createNetwork does not create a network when not authenticated", %{conn: conn} do
    network = params_for(:network)

    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"network" => network}

    assert %{
             "errors" => [first_error]
           } = json_response(conn, 200)

    refute is_nil(first_error)
  end

  test "createNetwork generates a slug from the title", %{conn: conn} do
    conn = Radiator.TestEntries.put_authenticated_user(conn)

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
                 "slug" => slug
               }
             }
           } = json_response(conn, 200)

    refute is_nil(slug)
    assert String.length(slug) > 0
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
      slug
    }
  }
  """

  test "updateNetwork updates a network", %{conn: conn} do
    network = insert(:network)

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"network" => %{title: "Meta meta!"}, "id" => network.id}

    id = Integer.to_string(network.id)

    assert %{
             "data" => %{
               "updateNetwork" => %{
                 "title" => "Meta meta!",
                 "id" => ^id
               }
             }
           } = json_response(conn, 200)
  end

  test "updateNetwork doesn't update the slug when title changes", %{conn: conn} do
    network = insert(:network)

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"network" => %{title: "Something New!"}, "id" => network.id}

    slug = network.slug

    assert %{
             "data" => %{
               "updateNetwork" => %{
                 "title" => "Something New!",
                 "slug" => ^slug
               }
             }
           } = json_response(conn, 200)
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
