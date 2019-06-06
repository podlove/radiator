defmodule RadiatorWeb.GraphQL.Schema.Mutation.EpisodesTest do
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
  mutation ($podcast_id: ID!, $episode: EpisodeInput!) {
    createEpisode(podcast_id: $podcast_id, episode: $episode) {
      id
      title
    }
  }
  """

  test "createEpisode creates an episode", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> owned_by(user)
    episode = params_for(:episode)

    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"episode" => episode, "podcast_id" => podcast.id}

    title = episode[:title]

    assert %{
             "data" => %{
               "createEpisode" => %{
                 "title" => ^title,
                 "id" => id
               }
             }
           } = json_response(conn, 200)

    refute is_nil(id)
  end

  test "createEpisode returns errors when missing data", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"episode" => %{}, "podcast_id" => podcast.id}

    assert %{
             "errors" => [
               %{"message" => msg}
             ]
           } = json_response(conn, 200)

    assert msg =~ ~r/Argument "episode" has invalid value \$episode/
  end

  test "createEpisode returns errors when podcast_id is wrong", %{conn: conn, user: _user} do
    episode = params_for(:episode)

    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"episode" => episode, "podcast_id" => -1}

    assert %{"errors" => [%{"message" => "Entity not found"}]} = json_response(conn, 200)
  end

  @update_query """
  mutation ($id: ID!, $episode: EpisodeInput!) {
    updateEpisode(id: $id, episode: $episode) {
      id
      title
      image
    }
  }
  """

  test "updateEpisode updates an episode", %{conn: conn, user: user} do
    episode = insert(:episode) |> owned_by(user)

    upload = %Plug.Upload{
      path: "test/fixtures/image.jpg",
      filename: "image.jpg"
    }

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"episode" => %{title: "Aldebaran", image: "myupload"}, "id" => episode.id},
        myupload: upload

    id = Integer.to_string(episode.id)

    assert %{
             "data" => %{
               "updateEpisode" => %{
                 "title" => "Aldebaran",
                 "id" => ^id,
                 "image" => image
               }
             }
           } = json_response(conn, 200)

    assert String.contains?(image, ".jpg")
  end

  test "updateEpisode returns an error when missing values", %{conn: conn, user: user} do
    episode = insert(:episode) |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"episode" => %{title: ""}, "id" => episode.id}

    assert %{"errors" => [%{"message" => msg}]} = json_response(conn, 200)
    assert msg == "title can't be blank"
  end

  @publish_query """
  mutation ($id: ID!) {
    publishEpisode(id: $id) {
      id
      publishedAt
      slug
    }
  }
  """

  test "publishEpisode publishes an episode", %{conn: conn, user: user} do
    episode = insert(:episode, published_at: nil) |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @publish_query,
        variables: %{"id" => episode.id}

    id = Integer.to_string(episode.id)

    assert %{
             "data" => %{
               "publishEpisode" => %{
                 "id" => ^id,
                 "publishedAt" => published
               }
             }
           } = json_response(conn, 200)

    refute is_nil(published)
  end

  test "publishEpisode generates an episodes slug", %{conn: conn, user: user} do
    episode = insert(:episode) |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @publish_query,
        variables: %{"id" => episode.id}

    id = Integer.to_string(episode.id)

    assert %{
             "data" => %{
               "publishEpisode" => %{
                 "id" => ^id,
                 "slug" => slug
               }
             }
           } = json_response(conn, 200)

    assert is_binary(slug)
    assert String.length(slug) > 0
  end

  test "publishEpisode doesn't generate slug, if episode already has one", %{
    conn: conn,
    user: user
  } do
    episode = insert(:episode, slug: "original-test-slug") |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @publish_query,
        variables: %{"id" => episode.id}

    id = Integer.to_string(episode.id)

    assert %{
             "data" => %{
               "publishEpisode" => %{
                 "id" => ^id,
                 "slug" => slug
               }
             }
           } = json_response(conn, 200)

    assert "original-test-slug" == slug
  end

  test "publishEpisode returns errors on wrong id", %{conn: conn, user: _user} do
    conn =
      post conn, "/api/graphql",
        query: @publish_query,
        variables: %{"id" => -1}

    assert %{"errors" => [%{"message" => "Entity not found"}]} = json_response(conn, 200)
  end

  @depublish_query """
  mutation ($id: ID!) {
    depublishEpisode(id: $id) {
      id
      publishedAt
    }
  }
  """

  test "depublishEpisode depublishes an episode", %{conn: conn, user: user} do
    episode = insert(:episode, published_at: DateTime.utc_now()) |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @depublish_query,
        variables: %{"id" => episode.id}

    id = Integer.to_string(episode.id)

    assert %{
             "data" => %{
               "depublishEpisode" => %{
                 "id" => ^id,
                 "publishedAt" => nil
               }
             }
           } = json_response(conn, 200)
  end

  test "depublishEpisode returns errors on wrong id", %{conn: conn, user: _user} do
    conn =
      post conn, "/api/graphql",
        query: @depublish_query,
        variables: %{"id" => -1}

    assert %{"errors" => [%{"message" => "Entity not found"}]} = json_response(conn, 200)
  end

  @schedule_query """
  mutation ($id: ID!, $datetime: DateTime) {
    scheduleEpisode(id: $id, datetime: $datetime) {
      id
      publishedAt
      slug
    }
  }
  """

  test "scheduleEpisode schedules episode for future", %{conn: conn, user: user} do
    episode = insert(:episode, published_at: nil) |> owned_by(user)

    schedule_date = DateTime.utc_now() |> DateTime.add(7200, :second) |> DateTime.to_iso8601()

    conn =
      post conn, "/api/graphql",
        query: @schedule_query,
        variables: %{"id" => episode.id, "datetime" => schedule_date}

    refute %{"errors" => _errors} = json_response(conn, 200)
  end

  @delete_query """
  mutation ($id: ID!) {
    deleteEpisode(id: $id) {
      id
      title
    }
  }
  """

  test "deleteEpisode deletes an episode", %{conn: conn, user: user} do
    episode = insert(:episode) |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @delete_query,
        variables: %{"id" => episode.id}

    title = episode.title
    id = Integer.to_string(episode.id)

    assert %{
             "data" => %{
               "deleteEpisode" => %{
                 "title" => ^title,
                 "id" => ^id
               }
             }
           } = json_response(conn, 200)
  end

  test "deleteEpisode returns an error for non-existing id", %{conn: conn, user: _user} do
    conn =
      post conn, "/api/graphql",
        query: @delete_query,
        variables: %{"id" => -1}

    assert %{"errors" => [%{"message" => "Entity not found"}]} = json_response(conn, 200)
  end

  @set_chapters_query """
  mutation ($id: ID!, $chapters: String!, $type: String!) {
    setChapters(id: $id, chapters: $chapters, type: $type) {
      chapters {
        start
        title
        link
      }
    }
  }
  """

  test "setChapters sets chapters for audio", %{conn: conn, user: user} do
    audio = insert(:audio) |> owned_by(user)

    chapters = ~S"""
    00:00:01.234 Intro <http://example.com>
    00:12:34.000 About us
    01:02:03.000 Later
    """

    conn =
      post conn, "/api/graphql",
        query: @set_chapters_query,
        variables: %{"chapters" => chapters, "id" => audio.id, "type" => "mp4chaps"}

    assert %{
             "data" => %{
               "setChapters" => %{
                 "chapters" => [
                   %{
                     "start" => 1234,
                     "title" => "Intro",
                     "link" => "http://example.com"
                   },
                   %{
                     "start" => 754_000,
                     "title" => "About us",
                     "link" => nil
                   },
                   %{
                     "start" => 3_723_000,
                     "title" => "Later",
                     "link" => nil
                   }
                 ]
               }
             }
           } = json_response(conn, 200)
  end
end
