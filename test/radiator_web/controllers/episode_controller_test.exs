defmodule RadiatorWeb.EpisodeControllerTest do
  use RadiatorWeb.ConnCase

  alias Radiator.Directory
  alias Radiator.Directory.Episode

  @create_attrs %{
    content: "some content",
    description: "some description",
    duration: "some duration",
    enclosure_length: 123,
    enclosure_type: "some enclosure_type",
    enclosure_url: "some enclosure_url",
    guid: "some guid",
    image: "some image",
    number: 42,
    published_at: "2010-04-17T14:00:00Z",
    subtitle: "some subtitle",
    title: "some title"
  }
  @update_attrs %{
    content: "some updated content",
    description: "some updated description",
    duration: "some updated duration",
    enclosure_length: 234,
    enclosure_type: "some updated enclosure_type",
    enclosure_url: "some updated enclosure_url",
    guid: "some updated guid",
    image: "some updated image",
    number: 43,
    published_at: "2011-05-18T15:01:01Z",
    subtitle: "some updated subtitle",
    title: "some updated title"
  }
  @invalid_attrs %{
    content: nil,
    description: nil,
    duration: nil,
    enclosure_length: nil,
    enclosure_type: nil,
    enclosure_url: nil,
    guid: nil,
    image: nil,
    number: nil,
    published_at: nil,
    subtitle: nil,
    title: nil
  }

  def fixture(:podcast) do
    {:ok, podcast} = Directory.create_podcast(%{title: "Example Podcast"})
    podcast
  end

  def fixture(:episode) do
    {:ok, episode} = Directory.create_episode(fixture(:podcast), @create_attrs)
    episode
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all episodes (empty)", %{conn: conn} do
      podcast = fixture(:podcast)
      index_path = Routes.api_podcast_episode_path(conn, :index, podcast.id)
      conn = get(conn, index_path)
      assert %{"_links" => %{"self" => %{"href" => index_path}}} = json_response(conn, 200)
    end

    test "lists all episodes", %{conn: conn} do
      episode = fixture(:episode)
      episode_id = episode.id
      index_path = Routes.api_podcast_episode_path(conn, :index, episode.podcast_id)
      conn = get(conn, index_path)

      assert %{
               "_links" => %{"self" => %{"href" => index_path}},
               "_embedded" => %{"rad:episode" => [%{"id" => ^episode_id}]}
             } = json_response(conn, 200)
    end
  end

  describe "create episode" do
    test "renders episode when data is valid", %{conn: conn} do
      podcast = fixture(:podcast)

      conn =
        post(conn, Routes.api_podcast_episode_path(conn, :create, podcast.id),
          episode: @create_attrs
        )

      assert %{"id" => id} = json_response(conn, 201)

      podcast_id = podcast.id
      episode_url = Routes.api_podcast_episode_path(conn, :show, podcast_id, id)
      conn = get(conn, episode_url)

      assert %{
               "_links" => %{
                 "self" => %{"href" => ^episode_url}
               },
               "_embedded" => %{
                 "rad:podcast" => %{
                   "id" => ^podcast_id
                 }
               },
               "id" => ^id,
               "content" => "some content",
               "description" => "some description",
               "duration" => "some duration",
               "enclosure_length" => 123,
               "enclosure_type" => "some enclosure_type",
               "enclosure_url" => "some enclosure_url",
               "guid" => "some guid",
               "image" => "some image",
               "number" => 42,
               "published_at" => "2010-04-17T14:00:00Z",
               "subtitle" => "some subtitle",
               "title" => "some title"
             } = json_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      podcast = fixture(:podcast)

      conn =
        post(conn, Routes.api_podcast_episode_path(conn, :create, podcast.id),
          episode: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "links to podcast", %{conn: conn} do
      podcast = fixture(:podcast)

      conn =
        post(conn, Routes.api_podcast_episode_path(conn, :create, podcast.id),
          episode: @create_attrs
        )

      podcast_path = Routes.api_podcast_path(conn, :show, podcast.id)

      assert %{
               "_links" => %{"rad:podcast" => %{"href" => ^podcast_path}}
             } = json_response(conn, 201)
    end
  end

  describe "update episode" do
    setup [:create_episode]

    test "renders episode when data is valid", %{conn: conn, episode: %Episode{id: id} = episode} do
      conn =
        put(conn, Routes.api_podcast_episode_path(conn, :update, episode.podcast.id, episode),
          episode: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)

      conn = get(conn, Routes.api_podcast_episode_path(conn, :show, episode.podcast.id, id))

      assert %{
               "id" => ^id,
               "content" => "some updated content",
               "description" => "some updated description",
               "duration" => "some updated duration",
               "enclosure_length" => 234,
               "enclosure_type" => "some updated enclosure_type",
               "enclosure_url" => "some updated enclosure_url",
               "guid" => "some updated guid",
               "image" => "some updated image",
               "number" => 43,
               "published_at" => "2011-05-18T15:01:01Z",
               "subtitle" => "some updated subtitle",
               "title" => "some updated title"
             } = json_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, episode: episode} do
      podcast = fixture(:podcast)

      conn =
        put(conn, Routes.api_podcast_episode_path(conn, :update, podcast.id, episode),
          episode: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete episode" do
    setup [:create_episode]

    test "deletes chosen episode", %{conn: conn, episode: episode} do
      conn =
        delete(conn, Routes.api_podcast_episode_path(conn, :delete, episode.podcast.id, episode))

      assert response(conn, 204)

      assert_error_sent 404, fn ->
        podcast = fixture(:podcast)
        get(conn, Routes.api_podcast_episode_path(conn, :show, podcast.id, episode))
      end
    end
  end

  defp create_episode(_) do
    episode = fixture(:episode)
    {:ok, episode: episode}
  end
end
