defmodule RadiatorWeb.EpisodeControllerTest.Schema.Mutation.EpisodesTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  @create_query """
  mutation ($podcast_id: ID!, $episode: EpisodeInput!) {
    createEpisode(podcast_id: $podcast_id, episode: $episode) {
      id
      title
    }
  }
  """

  test "createEpisode creates an episode", %{conn: conn} do
    podcast = insert(:podcast)
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

  test "createEpisode returns errors when missing data", %{conn: conn} do
    podcast = insert(:podcast)

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

  test "createEpisode returns errors when podcast_id is wrong", %{conn: conn} do
    episode = params_for(:episode)

    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"episode" => episode, "podcast_id" => -1}

    assert %{
             "errors" => [
               %{"message" => msg}
             ]
           } = json_response(conn, 200)

    assert msg == "Podcast ID -1 not found"
  end

  @update_query """
  mutation ($id: ID!, $episode: EpisodeInput!) {
    updateEpisode(id: $id, episode: $episode) {
      id
      title
    }
  }
  """

  test "updateEpisode updates an episode", %{conn: conn} do
    episode = insert(:episode)

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

  test "updateEpisode returns an error when missing values", %{conn: conn} do
    episode = insert(:episode)

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"episode" => %{title: ""}, "id" => episode.id}

    assert %{"errors" => [%{"message" => msg}]} = json_response(conn, 200)
    assert msg == "title can't be blank"
  end

  @delete_query """
  mutation ($id: ID!) {
    deleteEpisode(id: $id) {
      id
      title
    }
  }
  """

  test "deleteEpisode deletes a episode", %{conn: conn} do
    episode = insert(:episode)

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

  test "deleteEpisode returns an error for non-existing id", %{conn: conn} do
    conn =
      post conn, "/api/graphql",
        query: @delete_query,
        variables: %{"id" => -1}

    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "episode ID -1 not found"
  end
end
