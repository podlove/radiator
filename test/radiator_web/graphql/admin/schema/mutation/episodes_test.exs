defmodule RadiatorWeb.GraphQL.Schema.Mutation.EpisodesTest do
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
  mutation ($podcast_id: ID!, $episode: EpisodeInput!) {
    createEpisode(podcast_id: $podcast_id, episode: $episode) {
      id
      title
    }
  }
  """

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

  @update_query """
  mutation ($id: ID!, $episode: EpisodeInput!) {
    updateEpisode(id: $id, episode: $episode) {
      id
      title
    }
  }
  """

  test "updateEpisode updates an episode", %{conn: conn, user: user} do
    episode = insert(:episode) |> owned_by(user)

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"episode" => %{title: "Aldebaran"}, "id" => episode.id}

    id = Integer.to_string(episode.id)

    assert %{
             "data" => %{
               "updateEpisode" => %{
                 "title" => "Aldebaran",
                 "id" => ^id
               }
             }
           } = json_response(conn, 200)
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
      publishState
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
                 "publishState" => "depublished"
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

    schedule_date =
      DateTime.utc_now() |> DateTime.add(14400, :second) |> DateTime.truncate(:second)

    schedule_date_string = schedule_date |> DateTime.to_iso8601()

    conn =
      post conn, "/api/graphql",
        query: @schedule_query,
        variables: %{"id" => episode.id, "datetime" => schedule_date_string}

    assert %{"data" => %{"scheduleEpisode" => scheduled_episode}} = json_response(conn, 200)

    {:ok, scheduled_episode_date, _} =
      DateTime.from_iso8601(Map.get(scheduled_episode, "publishedAt"))

    assert schedule_date == scheduled_episode_date
    assert scheduled_episode_date > DateTime.utc_now()
  end

  test "scheduleEpisode rejects scheduling in the past", %{conn: conn, user: user} do
    episode = insert(:episode, published_at: nil) |> owned_by(user)

    schedule_date = DateTime.utc_now() |> DateTime.add(-1, :second) |> DateTime.truncate(:second)

    schedule_date_string = schedule_date |> DateTime.to_iso8601()

    conn =
      post conn, "/api/graphql",
        query: @schedule_query,
        variables: %{"id" => episode.id, "datetime" => schedule_date_string}

    assert %{"errors" => [%{"message" => "datetime_not_future"}]} = json_response(conn, 200)
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
end
