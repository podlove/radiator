defmodule RadiatorWeb.OutlineLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures

  describe "Outline page" do
    test "can render if user is logged in", %{conn: conn} do
      {:ok, _live, html} = conn |> log_in_user(user_fixture()) |> live(~p"/admin/outline")

      assert html =~ "Outline</h1>"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/outline")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "Outline page has an inbox" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user)}
    end

    test "inbox has a headline", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/admin/outline")

      assert live
             |> element("h2", "Inbox")
             |> render() =~ "Inbox"
    end
  end
end
