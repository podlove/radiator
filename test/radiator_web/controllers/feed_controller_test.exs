defmodule RadiatorWeb.FeedControllerTest do
  use RadiatorWeb.ConnCase

  import Radiator.Factory

  describe "#show" do
    test "renders the podcast feed", %{conn: conn} do
      podcast = insert(:podcast, title: "ACME Cast", short_id: "ACME", slug: "acme") |> publish()

      _episode = insert(:episode, title: "E001", podcast: podcast, slug: "e001") |> publish()

      conn = get(conn, Routes.feed_path(conn, :show, podcast.slug))

      assert redirected_to(conn, 307) =~ ".xml"
    end
  end
end
