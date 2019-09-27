defmodule RadiatorWeb.Public.EpisodeControllerTest do
  use RadiatorWeb.ConnCase

  alias Radiator.Directory

  import Radiator.Factory

  describe "#index" do
    test "renders published podcast" do
      podcast = insert(:podcast, title: "ACME Cast", short_id: "ACME", slug: "acme")

      conn = build_conn()
      conn = get(conn, Routes.episode_path(conn, :index, podcast.slug))

      response = response(conn, 200)
      assert response =~ podcast.title
    end

    test "does not render unpublished podcast" do
      podcast = insert(:unpublished_podcast, title: "ACME Cast", short_id: "ACME", slug: "acme")

      conn = build_conn()
      conn = get(conn, Routes.episode_path(conn, :index, podcast.slug))

      response = response(conn, 404)
      assert response =~ "Not Found"
    end
  end

  describe "#show" do
    test "renders published episode in published podcast" do
      podcast = insert(:podcast, title: "ACME Cast", short_id: "ACME", slug: "acme")
      episode = insert(:episode, title: "E001", podcast: podcast, slug: "e001")

      Directory.Editor.Manager.publish(episode)

      conn = build_conn()
      conn = get(conn, Routes.episode_path(conn, :show, podcast.slug, episode.slug))

      response = response(conn, 200)
      assert response =~ episode.title
    end

    test "does not render published episode in unpublished podcast" do
      podcast = insert(:unpublished_podcast, title: "ACME Cast", short_id: "ACME", slug: "acme")
      episode = insert(:episode, title: "E001", podcast: podcast, slug: "e001")

      Directory.Editor.Manager.publish(episode)

      conn = build_conn()
      conn = get(conn, Routes.episode_path(conn, :show, podcast.slug, episode.slug))

      response = response(conn, 404)
      assert response =~ "Not Found"
    end

    test "does not render unpublished episode" do
      podcast = insert(:podcast, title: "ACME Cast", short_id: "ACME", slug: "acme")
      episode = insert(:episode, title: "E001", podcast: podcast, slug: "e001")

      conn = build_conn()
      conn = get(conn, Routes.episode_path(conn, :show, podcast.slug, episode.slug))

      response = response(conn, 404)
      assert response =~ "Not Found"
    end
  end
end
