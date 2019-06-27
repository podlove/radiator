defmodule RadiatorWeb.GraphQL.Schema.Mutation.NetworksTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  @doc """
  Generate user and add auth token to connection.
  """
  def setup_user_and_conn(%{conn: conn}) do
    user = Radiator.TestEntries.user()

    [
      conn: Radiator.TestEntries.put_current_user(conn, user),
      user: user
    ]
  end

  setup :setup_user_and_conn

  @create_query """
  mutation ($network: NetworkInput!) {
    createNetwork(network: $network) {
      id
      title
      slug
    }
  }
  """

  test "createNetwork creates a network", %{conn: conn, user: _user} do
    conn = Radiator.TestEntries.put_current_user(conn)

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

  test "createNetwork does not create a network when not authenticated" do
    network = params_for(:network)

    conn =
      post build_conn(), "/api/graphql",
        query: @create_query,
        variables: %{"network" => network}

    assert %{
             "errors" => [first_error | _]
           } = json_response(conn, 200)

    refute is_nil(first_error)
  end

  test "createNetwork generates a slug from the title", %{conn: conn, user: _user} do
    conn = Radiator.TestEntries.put_current_user(conn)

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

  test "createNetwork returns error when missing data", %{conn: conn, user: _user} do
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
      image
      slug
    }
  }
  """

  test "updateNetwork updates a network", %{conn: conn, user: user} do
    network = insert(:network) |> owned_by(user)

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
                 "id" => ^id,
                 "image" => image
               }
             }
           } = json_response(conn, 200)

    assert String.contains?(image, ".jpg")
  end

  test "updateNetwork doesn't update the slug when title changes", %{conn: conn, user: user} do
    network = insert(:network) |> owned_by(user)

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

  test "updateNetwork returns errors on missing values", %{conn: conn, user: user} do
    network = insert(:network) |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"network" => %{title: ""}, "id" => network.id}

    assert %{"errors" => [%{"message" => msg}]} = json_response(conn, 200)
    assert msg == "title can't be blank"
  end
end
