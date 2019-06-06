defmodule RadiatorWeb.FeedControllerTest do
  use RadiatorWeb.ConnCase

  import Radiator.Factory

  describe "#show" do
    test "renders the podcast feed" do
      podcast = insert(:podcast, title: "ACME Cast")
      episode = insert(:published_episode, title: "E001", podcast: podcast)

      conn = build_conn()
      conn = get(conn, Routes.feed_path(conn, :show, podcast.id))

      response = response(conn, 200)

      assert response =~ podcast.title
      assert response =~ episode.title
    end

    test "dows not include episodes without enclosure" do
      podcast = insert(:podcast, title: "ACME Cast")

      episode =
        insert(:published_episode, title: "E001", podcast: podcast, audio: build(:empty_audio))

      conn = build_conn()
      conn = get(conn, Routes.feed_path(conn, :show, podcast.id))

      response = response(conn, 200)

      assert response =~ podcast.title
      refute response =~ episode.title
    end
  end
end
