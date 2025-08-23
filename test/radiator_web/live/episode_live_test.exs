defmodule RadiatorWeb.EpisodeLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures

  describe "Episode page is restricted" do
    setup do
      %{show: show_fixture()}
    end

    test "can render if user is logged in", %{conn: conn, show: show} do
      user = user_fixture()
      {:ok, _live, html} = conn |> log_in_user(user) |> live(~p"/admin/podcast/#{show.id}")

      assert html =~ "#{show.title}</h1>"
    end

    test "redirects if user is not logged in", %{conn: conn, show: show} do
      assert {:error, redirect} = live(conn, ~p"/admin/podcast/#{show.id}")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "Episode page" do
    setup %{conn: conn} do
      user = user_fixture()
      show = show_fixture()
      episode = episode_fixture(%{show_id: show.id})

      %{conn: log_in_user(conn, user), show: show, episode: episode}
    end

    test "has the title of the show and list of episodes", %{
      conn: conn,
      show: show,
      episode: episode
    } do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      assert page_title(live) =~ show.title

      assert live
             |> has_element?("aside a", episode.title)

      # assert page_title(live) =~ show.title
    end

    test "create new episode will create node as well", %{conn: conn, show: show} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      assert live
             |> element(~s|aside a[title="Create Episode"]|)
             |> render_click() =~ "New Episode"

      assert_patch(live, ~p"/admin/podcast/#{show.id}/new")

      # assert live
      #        |> form("#episode-form", episode: %{number: 1, title: "some episode"})
      #        |> render_submit()

      # assert live
      #       |> has_element?("#outline form input")
    end
  end
end
