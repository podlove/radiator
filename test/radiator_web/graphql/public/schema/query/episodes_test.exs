defmodule RadiatorWeb.GraphQL.Public.Schema.Query.EpisodesTest do
  use RadiatorWeb.ConnCase, async: true
  import Radiator.Factory

  alias Radiator.Media

  @single_query """
  query ($id: ID!) {
    publishedEpisode(id: $id) {
      id
      title
      audio {
        chapters {
          image
          link
          start
          title
        }
      }
    }
  }
  """

  test "episode returns an episode", %{conn: conn} do
    podcast = build(:podcast)

    upload = %Plug.Upload{
      path: "test/fixtures/image.jpg",
      filename: "image.jpg"
    }

    audio = insert(:audio)

    {:ok, chapter} =
      Radiator.AudioMeta.create_chapter(audio, %{
        image: upload,
        link: "http://example.com",
        title: "An Example",
        start: 12345
      })

    image_url = Media.ChapterImage.url({chapter.image, chapter})

    episode =
      insert(:published_episode,
        podcast: podcast,
        audio: audio
      )

    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => episode.id}

    assert image_url =~ "http"

    assert json_response(conn, 200) == %{
             "data" => %{
               "publishedEpisode" => %{
                 "id" => Integer.to_string(episode.id),
                 "title" => episode.title,
                 "audio" => %{
                   "chapters" => [
                     %{
                       "image" => image_url,
                       "link" => "http://example.com",
                       "title" => "An Example",
                       "start" => 12345
                     }
                   ]
                 }
               }
             }
           }
  end

  test "episode returns an error when queried with a non-existent ID", %{conn: conn} do
    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => -1}
    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Episode ID -1 not found"
  end

  test "episode returns an error if not published", %{conn: conn} do
    episode = insert(:unpublished_episode)

    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => episode.id}

    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Episode ID #{episode.id} not found"
  end

  @episodes_in_podcast_query """
  query ($podcast_id: ID!) {
    publishedPodcast(id: $podcast_id) {
      episodes {
        title
      }
    }
  }
  """

  test "episodes in podcast are ordered, latest first", %{conn: conn} do
    podcast = insert(:podcast)
    timestamp = 1_500_000_000

    _ep1 =
      insert(:published_episode,
        title: "E001",
        published_at: DateTime.from_unix!(timestamp),
        podcast: podcast
      )

    _ep3 =
      insert(:published_episode,
        title: "E003",
        published_at: DateTime.from_unix!(timestamp + 20),
        podcast: podcast
      )

    _ep2 =
      insert(:published_episode,
        title: "E002",
        published_at: DateTime.from_unix!(timestamp + 10),
        podcast: podcast
      )

    conn =
      get conn, "/api/graphql",
        query: @episodes_in_podcast_query,
        variables: %{"podcast_id" => podcast.id}

    assert %{
             "data" => %{
               "publishedPodcast" => %{
                 "episodes" => [
                   %{"title" => "E003"},
                   %{"title" => "E002"},
                   %{"title" => "E001"}
                 ]
               }
             }
           } = json_response(conn, 200)
  end
end
