defmodule RadiatorWeb.FeedControllerTest do
  use RadiatorWeb.ConnCase

  import Radiator.Factory

  test "#show renders the podcast feed" do
    podcast = insert(:podcast, title: "ACME Cast")
    episode = insert(:published_episode, title: "E001", podcast: podcast)

    conn = build_conn()
    conn = get(conn, Routes.feed_path(conn, :show, podcast.id))

    response = response(conn, 200)

    assert response =~ podcast.title
    assert response =~ episode.title
  end
end
