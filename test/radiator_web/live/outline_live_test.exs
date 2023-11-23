defmodule RadiatorWeb.OutlineLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures
  import Radiator.OutlineFixtures

  describe "Outline page is restricted" do
    test "can render if user is logged in", %{conn: conn} do
      user = user_fixture()
      {:ok, _live, html} = conn |> log_in_user(user) |> live(~p"/admin/outline")

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
      node = node_fixture()
      %{conn: log_in_user(conn, user), node: node}
    end

    test "lists all nodes", %{conn: conn, node: node} do
      {:ok, _live, html} = live(conn, ~p"/admin/outline")

      assert html =~ "Inbox</h2>"
      assert html =~ node.content
    end

    test "save new node", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/admin/outline")

      assert live
             |> form("#inbox-form", node: %{content: "new node content"})
             |> render_submit()

      assert live
             |> element("ul#inbox")
             |> render() =~ "new node content"
    end

    test "delete existing node", %{conn: conn, node: node} do
      {:ok, live, _html} = live(conn, ~p"/admin/outline")

      assert live
             |> element("#node-#{node.uuid} a", "Delete")
             |> render_click()

      refute live
             |> has_element?("#node-#{node.uuid}")
    end
  end
end
