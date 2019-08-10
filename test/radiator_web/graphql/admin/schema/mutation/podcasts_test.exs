defmodule RadiatorWeb.GraphQL.Schema.Mutation.PodcastsTest do
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

  @publish_query """
  mutation ($id: ID!) {
    publishPodcast(id: $id) {
      id
      publishedAt
      slug
    }
  }
  """

  test "publishPodcast publishes a podcast", %{conn: conn, user: user} do
    podcast = insert(:podcast, published_at: nil) |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @publish_query,
        variables: %{"id" => podcast.id}

    id = Integer.to_string(podcast.id)

    assert %{
             "data" => %{
               "publishPodcast" => %{
                 "id" => ^id,
                 "publishedAt" => published
               }
             }
           } = json_response(conn, 200)

    refute is_nil(published)
  end

  test "publishPodcast generates a podcasts slug", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @publish_query,
        variables: %{"id" => podcast.id}

    id = Integer.to_string(podcast.id)

    assert %{
             "data" => %{
               "publishPodcast" => %{
                 "id" => ^id,
                 "slug" => slug
               }
             }
           } = json_response(conn, 200)

    assert is_binary(slug)
    assert String.length(slug) > 0
  end

  test "publishPodcast doesn't generate slug, if podcast already has one", %{
    conn: conn,
    user: user
  } do
    podcast = insert(:podcast, slug: "original-test-slug") |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @publish_query,
        variables: %{"id" => podcast.id}

    id = Integer.to_string(podcast.id)

    assert %{
             "data" => %{
               "publishPodcast" => %{
                 "id" => ^id,
                 "slug" => slug
               }
             }
           } = json_response(conn, 200)

    assert "original-test-slug" == slug
  end

  test "publishPodcast returns errors on wrong id", %{conn: conn, user: _user} do
    conn =
      post conn, "/api/graphql",
        query: @publish_query,
        variables: %{"id" => -1}

    assert %{"errors" => [%{"message" => "Entity not found"}]} = json_response(conn, 200)
  end

  @depublish_query """
  mutation ($id: ID!) {
    depublishPodcast(id: $id) {
      id
      publishedAt
    }
  }
  """

  test "depublishPodcast depublishes a podcast", %{conn: conn, user: user} do
    podcast = insert(:podcast, published_at: DateTime.utc_now()) |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @depublish_query,
        variables: %{"id" => podcast.id}

    id = Integer.to_string(podcast.id)

    assert %{
             "data" => %{
               "depublishPodcast" => %{
                 "id" => ^id,
                 "publishedAt" => nil
               }
             }
           } = json_response(conn, 200)
  end

  test "depublishPodcast returns errors on wrong id", %{conn: conn, user: _user} do
    conn =
      post conn, "/api/graphql",
        query: @depublish_query,
        variables: %{"id" => -1}

    assert %{"errors" => [%{"message" => "Entity not found"}]} = json_response(conn, 200)
  end
end
