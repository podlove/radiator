defmodule RadiatorWeb.GraphQL.Admin.Schema.Query.NetworksTest do
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

  @single_query """
  query ($id: ID!) {
    network(id: $id) {
      id
      title
    }
  }
  """

  test "network returns a network", %{conn: conn, user: user} do
    network = insert(:network) |> owned_by(user)

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
end
