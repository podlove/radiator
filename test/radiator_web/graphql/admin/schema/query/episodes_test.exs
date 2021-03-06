defmodule RadiatorWeb.GraphQL.Admin.Schema.Query.EpisodesTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  alias Radiator.Media

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
    episode(id: $id) {
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

  test "episode returns an episode", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> publish() |> owned_by(user)

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

    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => episode.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "episode" => %{
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

  @episodes_in_podcast_query """
  query ($podcast_id: ID!) {
    podcast(id: $podcast_id) {
      episodes {
        title
      }
    }
  }
  """

  test "episodes in podcast are ordered, latest first", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> publish() |> owned_by(user)
    timestamp = 1_500_000_000

    _ep1 =
      insert(:episode,
        title: "E001",
        published_at: DateTime.from_unix!(timestamp),
        podcast: podcast
      )
      |> publish()

    _ep3 =
      insert(:episode,
        title: "E003",
        published_at: DateTime.from_unix!(timestamp + 20),
        podcast: podcast
      )
      |> publish()

    _ep2 =
      insert(:episode,
        title: "E002",
        published_at: DateTime.from_unix!(timestamp + 10),
        podcast: podcast
      )
      |> publish()

    conn =
      get conn, "/api/graphql",
        query: @episodes_in_podcast_query,
        variables: %{"podcast_id" => podcast.id}

    assert %{
             "data" => %{
               "podcast" => %{
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
