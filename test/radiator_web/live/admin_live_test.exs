defmodule RadiatorWeb.AdminLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures

  describe "Admin page" do
    test "can render if user is logged in", %{conn: conn} do
      {:ok, _live, html} = conn |> log_in_user(user_fixture()) |> live(~p"/admin")

      assert html =~ "Admin Dashboard</h1>"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "Admin page has links" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user)}
    end

    test "link to accounts", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/admin")

      {:ok, conn} =
        live
        |> element(~s|main a:fl-contains("Accounts")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/admin/accounts")

      assert conn.resp_body =~ "Accounts"
    end

    test "link to outline", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/admin")

      {:ok, conn} =
        live
        |> element(~s|main a:fl-contains("Outline")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/admin/outline")

      assert conn.resp_body =~ "Outline"
    end
  end
end
