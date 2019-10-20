defmodule RadiatorWeb.Public.EpisodeControllerTest do
  use RadiatorWeb.ConnCase

  import Radiator.Factory

  describe "#index" do
    test "renders published podcast", %{conn: conn} do
      podcast = insert(:podcast, title: "ACME Cast", short_id: "ACME", slug: "acme") |> publish()

      conn = get(conn, Routes.episode_path(conn, :index, podcast.slug))

      response = response(conn, 200)
      assert response =~ podcast.title
    end

    test "does not render unpublished podcast", %{conn: conn} do
      podcast = insert(:podcast, title: "ACME Cast", short_id: "ACME", slug: "acme")

      conn = get(conn, Routes.episode_path(conn, :index, podcast.slug))

      response = response(conn, 404)
      assert response =~ "Not Found"
    end
  end

  describe "#show" do
    test "renders published episode in published podcast", %{conn: conn} do
      podcast = insert(:podcast, title: "ACME Cast", short_id: "ACME", slug: "acme") |> publish()
      episode = insert(:episode, title: "E001", podcast: podcast, slug: "e001") |> publish()

      conn = get(conn, Routes.episode_path(conn, :show, podcast.slug, episode.slug))

      response = response(conn, 200)
      assert response =~ episode.title
    end

    test "does not render published episode in unpublished podcast", %{conn: conn} do
      podcast = insert(:podcast, title: "ACME Cast", short_id: "ACME", slug: "acme")
      episode = insert(:episode, title: "E001", podcast: podcast, slug: "e001") |> publish()

      conn = get(conn, Routes.episode_path(conn, :show, podcast.slug, episode.slug))

      response = response(conn, 404)
      assert response =~ "Not Found"
    end

    test "does not render unpublished episode", %{conn: conn} do
      podcast = insert(:podcast, title: "ACME Cast", short_id: "ACME", slug: "acme") |> publish()
      episode = insert(:episode, title: "E001", podcast: podcast, slug: "e001")

      conn = get(conn, Routes.episode_path(conn, :show, podcast.slug, episode.slug))

      response = response(conn, 404)
      assert response =~ "Not Found"
    end
  end
end
