defmodule RadiatorWeb.OutlineLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures
  import Radiator.OutlineFixtures

  alias Radiator.Outline

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
      {:ok, live, _html} = live(conn, ~p"/admin/outline")

      assert live |> element("h2", "Inbox")

      assert_push_event(live, "list", %{nodes: [^node]})
    end

    test "create a new node", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/admin/outline")

      temp_id = "f894d2ed-9447-4eef-8c31-fc52372b3bbe"
      params = %{"temp_id" => temp_id, "content" => "new node temp content"}

      assert live |> render_hook(:create_node, params)

      node =
        Outline.list_nodes()
        |> Enum.find(&(&1.content == "new node temp content"))
        |> Map.put(:temp_id, temp_id)

      assert_push_event(live, "update", ^node)
    end

    test "update node", %{conn: conn, node: node} do
      {:ok, live, _html} = live(conn, ~p"/admin/outline")

      params =
        node
        |> Map.from_struct()
        |> Map.put(:content, "update node content")

      assert live |> render_hook(:update_node, params)

      updated_node =
        Outline.list_nodes()
        |> Enum.find(&(&1.content == "update node content"))

      assert updated_node.uuid == params.uuid
      assert updated_node.content == params.content
    end
  end
end
