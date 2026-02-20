defmodule RadiatorWeb.PodcastsLiveTest do
  use RadiatorWeb.FeatureCase, async: true

  import Radiator.Generator

  defp create_podcast(%{conn: conn}) do
    podcast = generate(podcast())
    %{conn: conn, podcast: podcast}
  end

  test "unauthenticated conn has no access", %{conn: conn} do
    conn
    |> visit(~p"/admin/podcasts")
    |> assert_path(~p"/sign-in")
  end

  describe "authenticated conn can access routes" do
    setup [:register_and_log_in_user, :create_podcast]

    test "lists all podcasts", %{conn: conn, podcast: podcast} do
      conn
      |> visit(~p"/admin/podcasts")
      |> assert_has("h1", text: "Podcasts")
      |> assert_has("td", text: podcast.title)
    end
  end
end
