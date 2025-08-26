defmodule RadiatorWeb.AdminLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures

  describe "Admin page" do
    test "can render if user is logged in", %{conn: conn} do
      {:ok, _live, html} = conn |> log_in_user(user_fixture()) |> live(~p"/admin")

      assert html =~ "Admin Dashboard</h1>"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "Admin page contains" do
    setup %{conn: conn} do
      show = show_fixture()
      user = user_fixture()

      %{conn: log_in_user(conn, user), show: show}
    end

    test "links to each show", %{conn: conn, show: show} do
      {:ok, live, _html} = live(conn, ~p"/admin")

      {:ok, conn} =
        live
        |> element(~s{main a[href="/admin/podcast/#{show.id}"]})
        |> render_click()
        |> follow_redirect(conn, ~p"/admin/podcast/#{show.id}")

      assert conn.resp_body =~ show.title
    end

    test "link to accounts", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/admin")

      {:ok, conn} =
        live
        |> element(~s|main a[href="/admin/accounts"]|)
        |> render_click()
        |> follow_redirect(conn, ~p"/admin/accounts")

      assert conn.resp_body =~ "Accounts"
    end
  end
end
