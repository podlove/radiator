defmodule RadiatorWeb.GraphQL.Admin.Schema.Query.PodcastsTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  @doc """
  Generate user and add auth token to connection.
  """
  def setup_user_and_conn(%{conn: conn}) do
    user = Radiator.TestEntries.user()

    [
      conn: Radiator.TestEntries.put_authenticated_user(conn, user),
      user: user
    ]
  end

  setup :setup_user_and_conn

  @is_published_query """
  query ($id: ID!) {
    podcast(id: $id) {
      id
      isPublished
    }
  }
  """

  describe "is_published" do
    test "is false for an unpublished podcast", %{conn: conn, user: user} do
      podcast = insert(:unpublished_podcast) |> owned_by(user)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => podcast.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "podcast" => %{"id" => Integer.to_string(podcast.id), "isPublished" => false}
               }
             }
    end

    test "is true for a published podcast", %{conn: conn, user: user} do
      podcast = insert(:podcast, published_at: DateTime.utc_now()) |> owned_by(user)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => podcast.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "podcast" => %{"id" => Integer.to_string(podcast.id), "isPublished" => true}
               }
             }
    end

    # two tests here:
    # - no podcast found for public query
    # - isPublished is false for authenticated query
    test "is false for published_at dates in the future", %{conn: conn, user: user} do
      in_one_hour = DateTime.utc_now() |> DateTime.add(3600)
      podcast = insert(:podcast, published_at: in_one_hour) |> owned_by(user)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => podcast.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "podcast" => %{"id" => Integer.to_string(podcast.id), "isPublished" => false}
               }
             }
    end
  end
end
