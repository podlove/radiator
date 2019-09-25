defmodule RadiatorWeb.GraphQL.Admin.Schema.Query.PodcastsTest do
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
    podcast(id: $id) {
      id
      title
      publishState
    }
  }
  """

  test "podcast returns a podcast", %{conn: conn, user: user} do
    podcast = insert(:podcast, title: "Lorem") |> owned_by(user)

    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => podcast.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "podcast" => %{
                 "id" => Integer.to_string(podcast.id),
                 "title" => "Lorem",
                 "publishState" => "published"
               }
             }
           }
  end
end
