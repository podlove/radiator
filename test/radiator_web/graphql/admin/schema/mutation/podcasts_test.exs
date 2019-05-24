defmodule RadiatorWeb.GraphQL.Schema.Mutation.PodcastsTest do
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

  @create_query """
  mutation ($network_id: Int, $podcast: PodcastInput!) {
    createPodcast(network_id: $network_id, podcast: $podcast) {
      id
      title
    }
  }
  """

  test "createPodcast creates a podcast", %{conn: conn, user: user} do
    network = insert(:network) |> owned_by(user)
    podcast = params_for(:podcast)

    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"podcast" => %{title: podcast.title}, "network_id" => network.id}

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

  test "createPodcast returns errors when missing data", %{conn: conn, user: user} do
    network = insert(:network) |> owned_by(user)

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
      image
    }
  }
  """

  test "updatePodcast updates a podcast", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> owned_by(user)

    upload = %Plug.Upload{
      path: "test/fixtures/image.jpg",
      filename: "image.jpg"
    }

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"podcast" => %{title: "Aldebaran", image: "myupload"}, "id" => podcast.id},
        myupload: upload

    id = Integer.to_string(podcast.id)

    assert %{
             "data" => %{
               "updatePodcast" => %{
                 "title" => "Aldebaran",
                 "id" => ^id,
                 "image" => image
               }
             }
           } = json_response(conn, 200)

    assert String.contains?(image, ".jpg")
  end

  test "updatePodcast returns errors on missing values", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> owned_by(user)

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

    assert %{"errors" => [%{"message" => "Not Authorized"}]} = json_response(conn, 200)
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

    assert %{"errors" => [%{"message" => "Not Authorized"}]} = json_response(conn, 200)
  end

  @delete_query """
  mutation ($id: ID!) {
    deletePodcast(id: $id) {
      id
      title
    }
  }
  """

  test "deletePodcast deletes a podcast", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> owned_by(user)

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

  test "deletePodcast returns an error for non-existing id", %{conn: conn, user: _user} do
    conn =
      post conn, "/api/graphql",
        query: @delete_query,
        variables: %{"id" => -1}

    assert %{"errors" => [%{"message" => "Not Authorized"}]} = json_response(conn, 200)
  end
end
