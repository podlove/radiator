defmodule RadiatorWeb.OutlineLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures
  import Radiator.OutlineFixtures

  @additional_keep_alive 2000

  describe "Episode outline nodes" do
    setup %{conn: conn} do
      user = user_fixture()
      %{id: show_id} = show_fixture()
      %{id: episode_id} = episode_fixture(%{show_id: show_id})

      node_1 =
        node_fixture(
          episode_id: episode_id,
          parent_id: nil,
          prev_id: nil,
          content: "node_1"
        )

      node_2 =
        node_fixture(
          episode_id: episode_id,
          parent_id: nil,
          prev_id: node_1.uuid,
          content: "node_2"
        )

      node_2_1 =
        node_fixture(
          episode_id: episode_id,
          parent_id: node_2.uuid,
          prev_id: nil,
          content: "node_2_1"
        )

      node_3 =
        node_fixture(
          episode_id: episode_id,
          parent_id: nil,
          prev_id: node_2.uuid,
          content: "node_3"
        )

      %{
        conn: log_in_user(conn, user),
        url: ~p"/admin/podcast/#{show_id}",
        episode_id: episode_id,
        nodes: [node_1, node_2, node_2_1, node_3]
      }
    end

    test "lists all nodes", %{conn: conn, url: url, nodes: [node_1, node_2, node_2_1, node_3]} do
      {:ok, _live, html} = live(conn, url)

      assert html =~ node_1.content
      assert html =~ node_2.content
      assert html =~ node_2_1.content
      assert html =~ node_3.content
    end

    # assert view
    #    |> element("#inactive")
    #    |> render_blur() =~ "Tap to wake"

    # assert view
    #    |> element("#inactive")
    #    |> render_focus() =~ "Tap to wake"

    test "update node content", %{
      conn: conn,
      url: url,
      episode_id: episode_id,
      nodes: [%{uuid: uuid} | _]
    } do
      {:ok, live, _html} = live(conn, url)
      {:ok, other_live, _other_html} = live(conn, url)

      params = %{"uuid" => uuid, "content" => "node_1_updated"}

      assert live
             |> element("#outline-#{episode_id}-stream")
             |> render_hook(:save, params)

      keep_liveview_alive()

      assert_push_event(other_live, "set_content", %{uuid: ^uuid, content: "node_1_updated"})
    end

    test "insert a new node", %{
      conn: conn,
      url: url,
      episode_id: episode_id,
      nodes: [_, %{uuid: uuid} | _]
    } do
      {:ok, live, _html} = live(conn, url)
      {:ok, other_live, _html} = live(conn, url)

      params = %{
        "uuid" => uuid,
        "content" => "node_1_updated",
        "selection" => %{"start" => 2, "end" => 2}
      }

      assert live
             |> element("#outline-#{episode_id}-stream")
             |> render_hook(:new, params)

      keep_liveview_alive()

      assert_push_event(other_live, "set_content", %{uuid: ^uuid, content: "no"})

      assert live |> has_element?("#nodes-form-#{uuid}-content", "no")
      assert other_live |> has_element?("#nodes-form-#{uuid}-content", "no")
    end

    #   test "move node up", %{conn: conn, show_id: show_id, nodes: [node_1, node_2, _, node_3]} do
    #     {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")
    #     {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")

    #     assert live
    #            |> element("#form-#{node_2.uuid}_content")
    #            |> render_keydown(%{"key" => "ArrowUp", "altKey" => true})

    #     keep_liveview_alive()

    #     node_2_uuid = node_2.uuid
    #     assert_push_event(live, "move_nodes", %{nodes: nodes})
    #     assert_push_event(live, "focus_node", %{uuid: ^node_2_uuid})

    #     assert_push_event(other_live, "move_nodes", %{nodes: other_nodes})
    #     assert_push_event(other_live, "focus_node", %{uuid: ^node_2_uuid})

    #     node_map = nodes |> Enum.map(fn node -> {node.uuid, node} end) |> Map.new()

    #     assert length(nodes) == 3
    #     assert node_map[node_1.uuid].parent_id == node_1.parent_id
    #     assert node_map[node_1.uuid].prev_id == node_2.uuid

    #     assert node_map[node_2.uuid].parent_id == node_2.parent_id
    #     assert node_map[node_2.uuid].prev_id == nil

    #     assert node_map[node_3.uuid].parent_id == node_3.parent_id
    #     assert node_map[node_3.uuid].prev_id == node_1.uuid

    #     assert other_nodes == nodes
    #   end

    #   test "move node down", %{conn: conn, show_id: show_id, nodes: [node_1, node_2, _, node_3]} do
    #     {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")
    #     {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")

    #     assert live
    #            |> element("#form-#{node_1.uuid}_content")
    #            |> render_keydown(%{"key" => "ArrowDown", "altKey" => true})

    #     keep_liveview_alive()

    #     node_1_uuid = node_1.uuid
    #     assert_push_event(live, "move_nodes", %{nodes: nodes})
    #     assert_push_event(live, "focus_node", %{uuid: ^node_1_uuid})

    #     assert_push_event(other_live, "move_nodes", %{nodes: other_nodes})
    #     assert_push_event(other_live, "focus_node", %{uuid: ^node_1_uuid})

    #     node_map = nodes |> Enum.map(fn node -> {node.uuid, node} end) |> Map.new()

    #     assert length(nodes) == 3
    #     assert node_map[node_1.uuid].parent_id == node_1.parent_id
    #     assert node_map[node_1.uuid].prev_id == node_2.uuid

    #     assert node_map[node_2.uuid].parent_id == node_2.parent_id
    #     assert node_map[node_2.uuid].prev_id == nil

    #     assert node_map[node_3.uuid].parent_id == node_3.parent_id
    #     assert node_map[node_3.uuid].prev_id == node_1.uuid

    #     assert other_nodes == nodes
    #   end

    #   test "indent node", %{conn: conn, show_id: show_id, nodes: [node_1, node_2, _, node_3]} do
    #     {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")
    #     {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")

    #     assert live
    #            |> element("#form-#{node_2.uuid}_content")
    #            |> render_keydown(%{"key" => "Tab", "shiftKey" => false})

    #     keep_liveview_alive()

    #     node_2_uuid = node_2.uuid
    #     assert_push_event(live, "move_nodes", %{nodes: nodes})
    #     assert_push_event(live, "focus_node", %{uuid: ^node_2_uuid})

    #     assert_push_event(other_live, "move_nodes", %{nodes: other_nodes})
    #     assert_push_event(other_live, "focus_node", %{uuid: ^node_2_uuid})

    #     node_map = nodes |> Enum.map(fn node -> {node.uuid, node} end) |> Map.new()

    #     assert length(nodes) == 3
    #     assert node_map[node_1.uuid].parent_id == nil
    #     assert node_map[node_1.uuid].prev_id == nil

    #     assert node_map[node_2.uuid].parent_id == node_1.uuid
    #     assert node_map[node_2.uuid].prev_id == nil

    #     assert node_map[node_3.uuid].parent_id == nil
    #     assert node_map[node_3.uuid].prev_id == node_1.uuid

    #     assert other_nodes == nodes
    #   end

    #   test "outdent node", %{conn: conn, show_id: show_id, nodes: [_, node_2, node_2_1, node_3]} do
    #     {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")
    #     {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")

    #     assert live
    #            |> element("#form-#{node_2_1.uuid}_content")
    #            |> render_keydown(%{"key" => "Tab", "shiftKey" => true})

    #     keep_liveview_alive()

    #     node_2_1_uuid = node_2_1.uuid
    #     assert_push_event(live, "move_nodes", %{nodes: nodes})
    #     assert_push_event(live, "focus_node", %{uuid: ^node_2_1_uuid})

    #     assert_push_event(other_live, "move_nodes", %{nodes: other_nodes})
    #     assert_push_event(other_live, "focus_node", %{uuid: ^node_2_1_uuid})

    #     node_map = nodes |> Enum.map(fn node -> {node.uuid, node} end) |> Map.new()

    #     assert length(nodes) == 2
    #     assert node_map[node_2_1.uuid].parent_id == nil
    #     assert node_map[node_2_1.uuid].prev_id == node_2.uuid

    #     assert node_map[node_3.uuid].parent_id == nil
    #     assert node_map[node_3.uuid].prev_id == node_2_1.uuid

    #     assert other_nodes == nodes
    #   end

    #   # test "move node around", %{conn: conn, show: show, episode: episode, nodes: [node_1 | _]} do

    #   test "delete node", %{conn: conn, show_id: show_id, nodes: [_, _, _, node_3]} do
    #     {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")
    #     {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")

    #     assert live
    #            |> element("#form-#{node_3.uuid}_content")
    #            |> render_keydown(%{"key" => "Delete", "value" => ""})

    #     keep_liveview_alive()

    #     refute live |> has_element?("#form-#{node_3.uuid}")
    #     refute other_live |> has_element?("#form-#{node_3.uuid}")
    #   end
  end

  defp keep_liveview_alive do
    :timer.sleep(@additional_keep_alive)
  end
end
