defmodule RadiatorWeb.EpisodeLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures
  import Radiator.OutlineFixtures

  alias Radiator.Outline

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
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "Episode page" do
    setup %{conn: conn} do
      user = user_fixture()
      show = show_fixture()

      %{conn: log_in_user(conn, user), show: show}
    end

    test "has the title of the episode", %{conn: conn, show: show} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      assert page_title(live) =~ show.title
    end
  end

  describe "Episode outline nodes" do
    setup %{conn: conn} do
      user = user_fixture()
      show = show_fixture()
      episode = episode_fixture(%{show_id: show.id})

      node_1 = node_fixture(%{episode_id: episode.id})
      node_2 = node_fixture(%{episode_id: episode.id, prev_id: node_1.uuid})
      _node_21 = node_fixture(%{episode_id: episode.id, parent_id: node_2.uuid})

      %{conn: log_in_user(conn, user), show: show, episode: episode}
    end

    test "lists all nodes", %{conn: conn, show: show} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      nodes = Outline.list_nodes()

      assert_push_event(live, "list", %{nodes: ^nodes})
    end

    test "insert a new node", %{conn: conn, show: show} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
      {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      temp_id = "f894d2ed-9447-4eef-8c31-fc52372b3bbe"
      params = %{"temp_id" => temp_id, "content" => "new node temp content"}

      assert live |> render_hook(:create_node, params)

      node =
        Outline.list_nodes()
        |> Enum.find(&(&1.content == "new node temp content"))

      node_with_temp_id = Map.put(node, :temp_id, temp_id)

      assert_reply(live, ^node_with_temp_id)

      assert_push_event(other_live, "insert", ^node)
    end

    test "update node", %{conn: conn, show: show, episode: episode} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
      {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      node = node_fixture(%{episode_id: episode.id})

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

      assert_push_event(other_live, "update", ^updated_node)
    end

    test "delete node", %{conn: conn, show: show, episode: episode} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
      {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      node = node_fixture(%{episode_id: episode.id})
      params = Map.from_struct(node)

      assert live |> render_hook(:delete_node, params)

      assert_push_event(other_live, "delete", %{uuid: deleted_uuid})

      assert deleted_uuid == node.uuid
    end
  end
end
