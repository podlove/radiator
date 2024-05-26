defmodule RadiatorWeb.EpisodeLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures
  import Radiator.OutlineFixtures

  alias Radiator.Outline.Node
  alias Radiator.Outline.NodeRepository

  @additional_keep_alive 2000

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

      node = node_fixture(%{episode_id: episode.id})

      %{conn: log_in_user(conn, user), show: show, episode: episode, node: node}
    end

    test "lists all nodes", %{conn: conn, show: show} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      nodes = NodeRepository.list_nodes()

      assert_push_event(live, "list", %{nodes: ^nodes})
    end

    test "insert a new node", %{conn: conn, show: show, node: node} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
      {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      uuid = Ecto.UUID.generate()

      params = %{
        "uuid" => uuid,
        "content" => "new node content",
        # "parent_id" => nil,
        "prev_id" => node.uuid
      }

      assert live |> render_hook(:create_node, params)

      keep_liveview_alive()

      assert %Node{} = new_node = NodeRepository.get_node!(uuid)
      assert new_node.uuid == uuid
      assert new_node.parent_id == nil
      assert new_node.prev_id == node.uuid

      assert_push_event(live, "clean", %{node: %{uuid: ^uuid}})
      assert_push_event(other_live, "insert", %{node: ^new_node})
    end

    test "update node content", %{conn: conn, show: show, node: %{uuid: uuid}} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
      {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      content = "updated node content"
      params = %{"uuid" => uuid, "content" => content}

      assert live |> render_hook(:update_node_content, params)

      keep_liveview_alive()

      assert %Node{content: ^content} = NodeRepository.get_node!(uuid)

      assert_push_event(live, "clean", %{node: %{uuid: ^uuid}})
      assert_push_event(other_live, "change_content", %{node: %{uuid: ^uuid, content: ^content}})
    end

    test "move node", %{conn: conn, show: show, episode: episode, node: node1} do
      %{uuid: uuid1, parent_id: parent_id1} = node1

      uuid2 = Ecto.UUID.generate()

      node2 =
        node_fixture(%{
          uuid: uuid2,
          episode_id: episode.id,
          parent_id: parent_id1,
          prev_id: uuid1
        })

      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
      {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      params = node2 |> Map.merge(%{parent_id: uuid1, prev_id: nil}) |> Map.from_struct()

      assert live |> render_hook(:move_node, params)

      keep_liveview_alive()

      assert %Node{parent_id: ^uuid1} = NodeRepository.get_node!(uuid2)

      assert_push_event(live, "clean", %{node: %{uuid: ^uuid2}})

      assert_push_event(other_live, "move", %{
        node: %{uuid: ^uuid2, parent_id: ^uuid1, prev_id: nil}
      })
    end

    test "delete node", %{conn: conn, show: show, node: %{uuid: uuid}} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
      {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      params = %{"uuid" => uuid}

      assert live |> render_hook(:delete_node, params)

      keep_liveview_alive()

      assert NodeRepository.get_node(uuid) == nil

      assert_push_event(live, "clean", %{node: %{uuid: ^uuid}})
      assert_push_event(other_live, "delete", %{node: %{uuid: ^uuid}})
    end
  end

  defp keep_liveview_alive do
    :timer.sleep(@additional_keep_alive)
  end
end
