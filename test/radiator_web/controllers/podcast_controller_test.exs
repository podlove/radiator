defmodule RadiatorWeb.PodcastControllerTest do
  use RadiatorWeb.ConnCase

  import Radiator.Factory

  alias Radiator.Directory
  alias Radiator.Directory.Podcast
  alias Radiator.Directory.Editor

  @create_attrs %{
    author: "some author",
    description: "some description",
    language: "some language",
    last_built_at: "2010-04-17T14:00:00Z",
    owner_email: "some owner_email",
    owner_name: "some owner_name",
    published_at: "2010-04-17T14:00:00Z",
    subtitle: "some subtitle",
    title: "some title"
  }
  @update_attrs %{
    author: "some updated author",
    description: "some updated description",
    language: "some updated language",
    last_built_at: "2011-05-18T15:01:01Z",
    owner_email: "some updated owner_email",
    owner_name: "some updated owner_name",
    published_at: "2011-05-18T15:01:01Z",
    subtitle: "some updated subtitle",
    title: "some updated title"
  }
  @invalid_attrs %{
    author: nil,
    description: nil,
    language: nil,
    last_built_at: nil,
    owner_email: nil,
    owner_name: nil,
    published_at: nil,
    subtitle: nil,
    title: nil
  }

  def fixture(:podcast) do
    network = insert(:network)

    {:ok, podcast} = Editor.Manager.create_podcast(network, @create_attrs)
    podcast
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all podcasts (empty)", %{conn: conn} do
      index_path = Routes.api_podcast_path(conn, :index)
      conn = get(conn, index_path)
      assert %{"_links" => %{"self" => %{"href" => index_path}}} = json_response(conn, 200)
    end

    test "lists all podcasts", %{conn: conn} do
      podcast = fixture(:podcast)
      podcast_id = podcast.id
      index_path = Routes.api_podcast_path(conn, :index)
      conn = get(conn, index_path)

      assert %{
               "_links" => %{"self" => %{"href" => index_path}},
               "_embedded" => %{"rad:podcast" => [%{"id" => ^podcast_id}]}
             } = json_response(conn, 200)
    end
  end

  describe "create podcast" do
    test "renders podcast when data is valid", %{conn: conn} do
      network = insert(:network)

      conn =
        post(conn, Routes.api_podcast_path(conn, :create),
          podcast: @create_attrs,
          network_id: network.id
        )

      assert %{"id" => id} = json_response(conn, 201)

      conn = get(conn, Routes.api_podcast_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "author" => "some author",
               "description" => "some description",
               "language" => "some language",
               "last_built_at" => "2010-04-17T14:00:00Z",
               "owner_email" => "some owner_email",
               "owner_name" => "some owner_name",
               "published_at" => "2010-04-17T14:00:00Z",
               "subtitle" => "some subtitle",
               "title" => "some title"
             } = json_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      network = insert(:network)

      conn =
        post(conn, Routes.api_podcast_path(conn, :create),
          network_id: network.id,
          podcast: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "links to episodes", %{conn: conn} do
      network = insert(:network)

      conn =
        post(conn, Routes.api_podcast_path(conn, :create),
          network_id: network.id,
          podcast: @create_attrs
        )

      assert %{"id" => id} = json_response(conn, 201)

      index_path = Routes.api_podcast_episode_path(conn, :index, id)

      assert %{
               "_links" => %{"rad:episodes" => %{"href" => ^index_path}}
             } = json_response(conn, 201)
    end
  end

  describe "update podcast" do
    setup [:create_podcast]

    test "renders podcast when data is valid", %{conn: conn, podcast: %Podcast{id: id} = podcast} do
      conn = put(conn, Routes.api_podcast_path(conn, :update, podcast), podcast: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)

      conn = get(conn, Routes.api_podcast_path(conn, :show, id))

      assert %{
               "id" => id,
               "author" => "some updated author",
               "description" => "some updated description",
               "language" => "some updated language",
               "last_built_at" => "2011-05-18T15:01:01Z",
               "owner_email" => "some updated owner_email",
               "owner_name" => "some updated owner_name",
               "published_at" => "2011-05-18T15:01:01Z",
               "subtitle" => "some updated subtitle",
               "title" => "some updated title"
             } = json_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, podcast: podcast} do
      conn = put(conn, Routes.api_podcast_path(conn, :update, podcast), podcast: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete podcast" do
    setup [:create_podcast]

    test "deletes chosen podcast", %{conn: conn, podcast: podcast} do
      conn = delete(conn, Routes.api_podcast_path(conn, :delete, podcast))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.api_podcast_path(conn, :show, podcast))
      end
    end
  end

  defp create_podcast(_) do
    podcast = fixture(:podcast)
    {:ok, podcast: podcast}
  end
end
