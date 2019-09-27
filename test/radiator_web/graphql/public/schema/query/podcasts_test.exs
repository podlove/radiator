defmodule RadiatorWeb.GraphQL.Public.Schema.Query.PodcastsTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  alias Radiator.Media

  @list_query """
  {
    publishedPodcasts {
      id
      title
    }
  }
  """

  test "podcasts returns a list of published podcasts", %{conn: conn} do
    podcasts = insert_list(3, :podcast) |> publish()
    _podcast = insert(:podcast)

    conn = get conn, "/api/graphql", query: @list_query

    assert json_response(conn, 200) == %{
             "data" => %{
               "publishedPodcasts" =>
                 Enum.map(podcasts, &%{"id" => Integer.to_string(&1.id), "title" => &1.title})
             }
           }
  end

  @single_query """
  query ($id: ID!) {
    publishedPodcast(id: $id) {
      id
      title
      episodes {
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
  }
  """

  test "podcast returns a podcast", %{conn: conn} do
    podcast = insert(:podcast) |> publish()

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
      insert(:episode,
        podcast: podcast,
        audio: audio
      )
      |> publish()

    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => podcast.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "publishedPodcast" => %{
                 "id" => Integer.to_string(podcast.id),
                 "title" => podcast.title,
                 "episodes" => [
                   %{
                     "audio" => %{
                       "chapters" => [
                         %{
                           "image" => image_url,
                           "link" => "http://example.com",
                           "title" => "An Example",
                           "start" => 12345
                         }
                       ]
                     },
                     "id" => to_string(episode.id),
                     "title" => episode.title
                   }
                 ]
               }
             }
           }
  end

  test "podcast returns an error when queried with a non-existent ID", %{conn: conn} do
    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => -1}
    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Podcast ID -1 not found"
  end

  test "podcast returns an error if not published", %{conn: conn} do
    podcast = insert(:podcast)
    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => podcast.id}

    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message == "Podcast ID #{podcast.id} not found"
  end

  describe "episodes" do
    @with_episodes_query """
    query ($id: ID!) {
      publishedPodcast(id: $id) {
        id
        episodes {
          id
          title
        }
      }
    }
    """

    test "returns all published episodes of a podcast", %{conn: conn} do
      podcast = insert(:podcast) |> publish()
      episode = insert(:episode, podcast: podcast) |> publish()
      _episode = insert(:episode, podcast: podcast)

      conn =
        get conn, "/api/graphql", query: @with_episodes_query, variables: %{"id" => podcast.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "publishedPodcast" => %{
                   "id" => Integer.to_string(podcast.id),
                   "episodes" => [
                     %{"id" => Integer.to_string(episode.id), "title" => episode.title}
                   ]
                 }
               }
             }
    end
  end

  describe "episodes_count" do
    @with_episodes_count_query """
    query ($id: ID!) {
      publishedPodcast(id: $id) {
        id
        publishedEpisodesCount
      }
    }
    """

    test "returns the number of published episodes associated to a podcast", %{conn: conn} do
      podcast = insert(:podcast) |> publish()
      _episode1 = insert(:episode, podcast: podcast) |> publish()
      _episode2 = insert(:episode, podcast: podcast) |> publish()
      _episode3 = insert(:episode, podcast: podcast)

      conn =
        get conn, "/api/graphql",
          query: @with_episodes_count_query,
          variables: %{"id" => podcast.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "publishedPodcast" => %{
                   "id" => Integer.to_string(podcast.id),
                   "publishedEpisodesCount" => 2
                 }
               }
             }
    end
  end
end
