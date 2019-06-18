defmodule RadiatorWeb.EpisodeControllerTest do
  use RadiatorWeb.ConnCase

  import Radiator.Factory

  alias Radiator.Directory.Episode
  alias Radiator.Directory.Editor

  @create_attrs %{
    content: "some content",
    description: "some description",
    guid: "some guid",
    number: 42,
    published_at: "2010-04-17T14:00:00Z",
    subtitle: "some subtitle",
    title: "some title"
  }
  @update_attrs %{
    content: "some updated content",
    description: "some updated description",
    guid: "some updated guid",
    number: 43,
    published_at: "2011-05-18T15:01:01Z",
    subtitle: "some updated subtitle",
    title: "some updated title"
  }
  @invalid_attrs %{
    content: nil,
    description: nil,
    guid: nil,
    number: nil,
    published_at: nil,
    subtitle: nil,
    title: nil
  }

  def fixture(:podcast) do
    network = insert(:network)

    {:ok, podcast} =
      Editor.Manager.create_podcast(network, %{
        title: "Example Podcast",
        published_at: "2009-05-18T15:01:01Z"
      })

    podcast
  end

  def fixture(:episode) do
    insert(:episode, @create_attrs |> Map.put(:podcast, fixture(:podcast)))
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
               "guid" => "some guid",
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
               "guid" => "some updated guid",
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
      podcast_id = episode.podcast.id

      conn = delete(conn, Routes.api_podcast_episode_path(conn, :delete, podcast_id, episode))
      assert response(conn, 204)

      conn = get(conn, Routes.api_podcast_episode_path(conn, :show, podcast_id, episode))
      assert response(conn, 404)
    end
  end

  defp create_episode(_) do
    episode = fixture(:episode)
    {:ok, episode: episode}
  end
end
