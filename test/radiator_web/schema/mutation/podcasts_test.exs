defmodule RadiatorWeb.EpisodeControllerTest.Schema.Mutation.PodcastsTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  @create_query """
  mutation ($network_id: Int, $podcast: PodcastInput!) {
    createPodcast(network_id: $network_id, podcast: $podcast) {
      id
      title
    }
  }
  """

  test "createPodcast creates a podcast", %{conn: conn} do
    network = insert(:network)
    podcast = params_for(:podcast)

    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"podcast" => podcast, "network_id" => network.id}

    title = podcast[:title]

    assert %{
             "data" => %{
               "createPodcast" => %{
                 "title" => ^title,
                 "id" => id
               }
             }
           } = json_response(conn, 200)

    refute is_nil(id)
  end

  test "createPodcast returns errors when missing data", %{conn: conn} do
    network = insert(:network)

    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"podcast" => %{}, "network_id" => network.id}

    assert %{
             "errors" => [
               %{"message" => msg}
             ]
           } = json_response(conn, 200)

    assert msg =~ ~r/Argument "podcast" has invalid value \$podcast/
  end

  @update_query """
  mutation ($id: ID!, $podcast: PodcastInput!) {
    updatePodcast(id: $id, podcast: $podcast) {
      id
      title
    }
  }
  """

  test "updatePodcast updates a podcast", %{conn: conn} do
    podcast = insert(:podcast)

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"podcast" => %{title: "Aldebaran"}, "id" => podcast.id}

    id = Integer.to_string(podcast.id)

    assert %{
             "data" => %{
               "updatePodcast" => %{
                 "title" => "Aldebaran",
                 "id" => ^id
               }
             }
           } = json_response(conn, 200)
  end

  test "updatePodcast returns errors on missing values", %{conn: conn} do
    podcast = insert(:podcast)

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"podcast" => %{title: ""}, "id" => podcast.id}

    assert %{"errors" => [%{"message" => msg}]} = json_response(conn, 200)
    assert msg == "title can't be blank"
  end

  @publish_query """
  mutation ($id: ID!) {
    publishPodcast(id: $id) {
      id
      publishedAt
    }
  }
  """

  test "publishPodcast publishes a podcast", %{conn: conn} do
    podcast = insert(:podcast, published_at: nil)

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

  test "publishPodcast returns errors on wrong id", %{conn: conn} do
    conn =
      post conn, "/api/graphql",
        query: @publish_query,
        variables: %{"id" => -1}

    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Podcast ID -1 not found"
  end

  @depublish_query """
  mutation ($id: ID!) {
    depublishPodcast(id: $id) {
      id
      publishedAt
    }
  }
  """

  test "depublishPodcast depublishes a podcast", %{conn: conn} do
    podcast = insert(:podcast, published_at: DateTime.utc_now())

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

  test "depublishPodcast returns errors on wrong id", %{conn: conn} do
    conn =
      post conn, "/api/graphql",
        query: @depublish_query,
        variables: %{"id" => -1}

    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Podcast ID -1 not found"
  end

  @delete_query """
  mutation ($id: ID!) {
    deletePodcast(id: $id) {
      id
      title
    }
  }
  """

  test "deletePodcast deletes a podcast", %{conn: conn} do
    podcast = insert(:podcast)

    conn =
      post conn, "/api/graphql",
        query: @delete_query,
        variables: %{"id" => podcast.id}

    title = podcast.title
    id = Integer.to_string(podcast.id)

    assert %{
             "data" => %{
               "deletePodcast" => %{
                 "title" => ^title,
                 "id" => ^id
               }
             }
           } = json_response(conn, 200)
  end

  test "deletePodcast returns an error for non-existing id", %{conn: conn} do
    conn =
      post conn, "/api/graphql",
        query: @delete_query,
        variables: %{"id" => -1}

    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Podcast ID -1 not found"
  end
end
