defmodule RadiatorWeb.OutlineLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures
  import Radiator.OutlineFixtures

  alias RadiatorWeb.OutlineLive

  @additional_keep_alive 2000

  describe "Episode outline nodes" do
    setup %{conn: conn} do
      user = user_fixture()
      show = show_fixture()

      %{outline_node_container_id: outline_node_container_id} =
        episode_fixture(%{show_id: show.id})

      node_1 =
        node_fixture(
          container_id: outline_node_container_id,
          parent_id: nil,
          prev_id: nil,
          content: "node_1"
        )

      node_2 =
        node_fixture(
          container_id: outline_node_container_id,
          parent_id: nil,
          prev_id: node_1.uuid,
          content: "node_2"
        )

      node_2_1 =
        node_fixture(
          container_id: outline_node_container_id,
          parent_id: node_2.uuid,
          prev_id: nil,
          content: "node_2_1"
        )

      node_3 =
        node_fixture(
          container_id: outline_node_container_id,
          parent_id: nil,
          prev_id: node_2.uuid,
          content: "node_3"
        )

      %{
        conn: log_in_user(conn, user),
        user: user,
        stream_id: "#outline-#{outline_node_container_id}-stream",
        nodes: [node_1, node_2, node_2_1, node_3],
        outline_node_container_id: outline_node_container_id
      }
    end

    test "lists all nodes", %{
      conn: conn,
      user: user,
      outline_node_container_id: container_id,
      nodes: [node_1, node_2, node_2_1, node_3]
    } do
      session = %{
        "container_id" => container_id,
        "user_id" => user.id
      }

      {:ok, _live, html} =
        live_isolated(conn, OutlineLive.Index, session: session)

      assert html =~ node_1.content
      assert html =~ node_2.content
      assert html =~ node_2_1.content
      assert html =~ node_3.content
    end

    test "focus node", %{
      conn: conn,
      outline_node_container_id: outline_node_container_id,
      user: user,
      nodes: [%{uuid: uuid} | _]
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      assert live
             |> element("#nodes-form-#{uuid} .content")
             |> render_focus()

      keep_liveview_alive()

      user_id = user.id
      assert_push_event(live, "focus", %{uuid: ^uuid, user_id: ^user_id})
      assert_push_event(other_live, "focus", %{uuid: ^uuid, user_id: ^user_id})
    end

    test "blur node", %{
      conn: conn,
      user: user,
      outline_node_container_id: outline_node_container_id,
      nodes: [%{uuid: uuid} | _]
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      assert live
             |> element("#nodes-form-#{uuid} .content")
             |> render_blur()

      keep_liveview_alive()

      user_id = user.id
      assert_push_event(live, "blur", %{uuid: ^uuid, user_id: ^user_id})
      assert_push_event(other_live, "blur", %{uuid: ^uuid, user_id: ^user_id})
    end

    test "update node content", %{
      conn: conn,
      user: user,
      stream_id: stream_id,
      nodes: [%{uuid: uuid} | _],
      outline_node_container_id: outline_node_container_id
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      params = %{"uuid" => uuid, "content" => "node_1_updated"}

      assert live
             |> element(stream_id)
             |> render_hook(:save, params)

      keep_liveview_alive()
      assert_push_event(other_live, "set_content", %{uuid: ^uuid, content: "node_1_updated"})
    end

    test "split node", %{
      conn: conn,
      user: user,
      outline_node_container_id: outline_node_container_id,
      stream_id: stream_id,
      nodes: [%{uuid: uuid} | _]
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      params = %{
        "uuid" => uuid,
        "content" => "node_1",
        "start" => 2,
        "stop" => 2
      }

      assert live
             |> element(stream_id)
             |> render_hook(:split, params)

      keep_liveview_alive()

      assert_push_event(live, "set_content", %{uuid: ^uuid, content: "no"})
      assert_push_event(other_live, "set_content", %{uuid: ^uuid, content: "no"})

      assert live |> has_element?(".node", "de_1")
      assert other_live |> has_element?(".node", "de_1")
    end

    test "merge node with next", %{
      conn: conn,
      user: user,
      outline_node_container_id: outline_node_container_id,
      stream_id: stream_id,
      nodes: [node_1, node_2, node_2_1, node_3]
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      params = %{"uuid" => node_1.uuid}

      assert live
             |> element(stream_id)
             |> render_hook(:merge_next, params)

      keep_liveview_alive()

      node_1_uuid = node_1.uuid
      node_3_uuid = node_3.uuid
      node_2_1_uuid = node_2_1.uuid
      content = node_1.content <> node_2.content

      assert_push_event(live, "set_content", %{uuid: ^node_1_uuid, content: ^content})
      assert_push_event(other_live, "set_content", %{uuid: ^node_1_uuid, content: ^content})

      assert_push_event(live, "move_nodes", %{
        nodes: [%{uuid: ^node_3_uuid, prev_id: ^node_1_uuid}]
      })

      assert_push_event(other_live, "move_nodes", %{
        nodes: [%{uuid: ^node_3_uuid, prev_id: ^node_1_uuid}]
      })

      assert_push_event(live, "move_nodes", %{nodes: [moved_node]})
      assert_push_event(other_live, "move_nodes", %{nodes: [other_moved_node]})

      assert %{uuid: ^node_2_1_uuid} = moved_node
      assert moved_node == other_moved_node

      assert live |> has_element?("#nodes-form-#{node_1.uuid}")
      assert other_live |> has_element?("#nodes-form-#{node_1.uuid}")

      refute live |> has_element?("#nodes-form-#{node_2.uuid}")
      refute other_live |> has_element?("#nodes-form-#{node_2.uuid}")
    end

    test "merge node with prev", %{
      conn: conn,
      user: user,
      outline_node_container_id: outline_node_container_id,
      stream_id: stream_id,
      nodes: [node_1, node_2, node_2_1, node_3]
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      params = %{"uuid" => node_2.uuid}

      assert live
             |> element(stream_id)
             |> render_hook(:merge_prev, params)

      keep_liveview_alive()

      node_1_uuid = node_1.uuid
      node_3_uuid = node_3.uuid
      node_2_1_uuid = node_2_1.uuid
      content = node_1.content <> node_2.content

      assert_push_event(live, "set_content", %{uuid: ^node_1_uuid, content: ^content})
      assert_push_event(other_live, "set_content", %{uuid: ^node_1_uuid, content: ^content})

      assert_push_event(live, "move_nodes", %{
        nodes: [%{uuid: ^node_3_uuid, prev_id: ^node_1_uuid}]
      })

      assert_push_event(other_live, "move_nodes", %{
        nodes: [%{uuid: ^node_3_uuid, prev_id: ^node_1_uuid}]
      })

      assert_push_event(live, "move_nodes", %{nodes: [moved_child_node]})
      assert_push_event(other_live, "move_nodes", %{nodes: [other_moved_child_node]})

      assert %{uuid: ^node_2_1_uuid} = moved_child_node
      assert moved_child_node == other_moved_child_node

      assert live |> has_element?("#nodes-form-#{node_1.uuid}")
      assert other_live |> has_element?("#nodes-form-#{node_1.uuid}")

      refute live |> has_element?("#nodes-form-#{node_2.uuid}")
      refute other_live |> has_element?("#nodes-form-#{node_2.uuid}")
    end

    test "move node up", %{
      conn: conn,
      user: user,
      outline_node_container_id: outline_node_container_id,
      stream_id: stream_id,
      nodes: [node_1, node_2, _, node_3]
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      params = %{"uuid" => node_2.uuid}

      assert live
             |> element(stream_id)
             |> render_hook(:move_up, params)

      keep_liveview_alive()

      node_2_uuid = node_2.uuid
      assert_push_event(live, "move_nodes", %{nodes: nodes})
      assert_push_event(live, "focus_node", %{uuid: ^node_2_uuid})

      assert_push_event(other_live, "move_nodes", %{nodes: other_nodes})

      node_map = nodes |> Enum.map(fn node -> {node.uuid, node} end) |> Map.new()

      assert length(nodes) == 3
      assert node_map[node_1.uuid].parent_id == node_1.parent_id
      assert node_map[node_1.uuid].prev_id == node_2.uuid

      assert node_map[node_2.uuid].parent_id == node_2.parent_id
      assert node_map[node_2.uuid].prev_id == nil

      assert node_map[node_3.uuid].parent_id == node_3.parent_id
      assert node_map[node_3.uuid].prev_id == node_1.uuid

      assert other_nodes == nodes
    end

    test "move node down", %{
      conn: conn,
      user: user,
      outline_node_container_id: outline_node_container_id,
      stream_id: stream_id,
      nodes: [node_1, node_2, _, node_3]
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      params = %{"uuid" => node_1.uuid}

      assert live
             |> element(stream_id)
             |> render_hook(:move_down, params)

      keep_liveview_alive()

      node_1_uuid = node_1.uuid
      assert_push_event(live, "move_nodes", %{nodes: nodes})
      assert_push_event(live, "focus_node", %{uuid: ^node_1_uuid})

      assert_push_event(other_live, "move_nodes", %{nodes: other_nodes})

      node_map = nodes |> Enum.map(fn node -> {node.uuid, node} end) |> Map.new()

      assert length(nodes) == 3
      assert node_map[node_1.uuid].parent_id == node_1.parent_id
      assert node_map[node_1.uuid].prev_id == node_2.uuid

      assert node_map[node_2.uuid].parent_id == node_2.parent_id
      assert node_map[node_2.uuid].prev_id == nil

      assert node_map[node_3.uuid].parent_id == node_3.parent_id
      assert node_map[node_3.uuid].prev_id == node_1.uuid

      assert other_nodes == nodes
    end

    test "indent node", %{
      conn: conn,
      user: user,
      outline_node_container_id: outline_node_container_id,
      stream_id: stream_id,
      nodes: [node_1, node_2, _, node_3]
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      params = %{"uuid" => node_2.uuid}

      assert live
             |> element(stream_id)
             |> render_hook(:indent, params)

      keep_liveview_alive()

      node_2_uuid = node_2.uuid
      assert_push_event(live, "move_nodes", %{nodes: nodes})
      assert_push_event(live, "focus_node", %{uuid: ^node_2_uuid})

      assert_push_event(other_live, "move_nodes", %{nodes: other_nodes})

      node_map = nodes |> Enum.map(fn node -> {node.uuid, node} end) |> Map.new()

      assert length(nodes) == 3
      assert node_map[node_1.uuid].parent_id == nil
      assert node_map[node_1.uuid].prev_id == nil

      assert node_map[node_2.uuid].parent_id == node_1.uuid
      assert node_map[node_2.uuid].prev_id == nil

      assert node_map[node_3.uuid].parent_id == nil
      assert node_map[node_3.uuid].prev_id == node_1.uuid

      assert other_nodes == nodes
    end

    test "outdent node", %{
      conn: conn,
      user: user,
      outline_node_container_id: outline_node_container_id,
      stream_id: stream_id,
      nodes: [_, node_2, node_2_1, node_3]
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      params = %{"uuid" => node_2_1.uuid}

      assert live
             |> element(stream_id)
             |> render_hook(:outdent, params)

      keep_liveview_alive()

      node_2_1_uuid = node_2_1.uuid
      assert_push_event(live, "move_nodes", %{nodes: nodes})
      assert_push_event(live, "focus_node", %{uuid: ^node_2_1_uuid})

      assert_push_event(other_live, "move_nodes", %{nodes: other_nodes})

      node_map = nodes |> Enum.map(fn node -> {node.uuid, node} end) |> Map.new()

      assert length(nodes) == 2
      assert node_map[node_2_1.uuid].parent_id == nil
      assert node_map[node_2_1.uuid].prev_id == node_2.uuid

      assert node_map[node_3.uuid].parent_id == nil
      assert node_map[node_3.uuid].prev_id == node_2_1.uuid

      assert other_nodes == nodes
    end

    test "move node to different position", %{
      conn: conn,
      user: user,
      outline_node_container_id: outline_node_container_id,
      stream_id: stream_id,
      nodes: [node_1, node_2, node_2_1 | _]
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      params = %{"uuid" => node_2_1.uuid, "prev_id" => node_1.uuid}

      assert live
             |> element(stream_id)
             |> render_hook(:move, params)

      keep_liveview_alive()

      node_2_1_uuid = node_2_1.uuid
      assert_push_event(live, "move_nodes", %{nodes: nodes})
      assert_push_event(live, "focus_node", %{uuid: ^node_2_1_uuid})

      assert_push_event(other_live, "move_nodes", %{nodes: other_nodes})

      node_map = nodes |> Enum.map(fn node -> {node.uuid, node} end) |> Map.new()

      assert length(nodes) == 2
      assert node_map[node_2_1.uuid].parent_id == nil
      assert node_map[node_2_1.uuid].prev_id == node_1.uuid

      assert node_map[node_2.uuid].parent_id == nil
      assert node_map[node_2.uuid].prev_id == node_2_1.uuid

      assert other_nodes == nodes
    end

    #     @tag :skip
    # test "merge with prev node", %{
    #       conn: conn,
    #       url: url,
    #       stream_id: stream_id,
    #       nodes: [node_1, node_2, _, node_3]
    #     } do
    #       {:ok, live, _html} = live(conn, url)
    #       {:ok, other_live, _html} = live(conn, url)

    #       params = %{"uuid" => node_2.uuid, "content" => node_2.content}

    #       assert live
    #              |> element(stream_id)
    #              |> render_hook(:merge_prev, params)

    #       keep_liveview_alive()

    #       node_1_uuid = node_1.uuid
    #       node_3_uuid = node_3.uuid
    #       content = node_1.content <> node_2.content
    #       assert_push_event(other_live, "set_content", %{uuid: ^node_1_uuid, content: ^content})

    #       assert_push_event(live, "move_nodes", %{nodes: [moved_node]})
    #       assert_push_event(other_live, "move_nodes", %{nodes: [other_moved_node]})

    #       assert %{uuid: ^node_3_uuid, parent_id: nil, prev_id: ^node_1_uuid} = moved_node
    #       assert moved_node == other_moved_node

    #       refute live |> has_element?("#nodes-form-#{node_2.uuid}")
    #       refute other_live |> has_element?("#nodes-form-#{node_2.uuid}")

    #       assert live |> has_element?("#nodes-form-#{node_1.uuid}")
    #       assert other_live |> has_element?("#nodes-form-#{node_1.uuid}")
    #     end
    # #
    # @tag :skip
    # test "merging with next node", %{
    #   conn: conn,
    #   url: url,
    #   stream_id: stream_id,
    #   nodes: [node_1, node_2, _, node_3]
    # } do
    #   {:ok, live, _html} = live(conn, url)
    #   {:ok, other_live, _html} = live(conn, url)

    #   params = %{"uuid" => node_1.uuid, "content" => node_1.content}

    #   assert live
    #          |> element(stream_id)
    #          |> render_hook(:merge_next, params)

    #   keep_liveview_alive()

    #   node_1_uuid = node_1.uuid
    #   node_3_uuid = node_3.uuid
    #   content = node_1.content <> node_2.content
    #   assert_push_event(other_live, "set_content", %{uuid: ^node_1_uuid, content: ^content})

    #   assert_push_event(live, "move_nodes", %{nodes: [moved_node]})
    #   assert_push_event(other_live, "move_nodes", %{nodes: [other_moved_node]})

    #   assert %{uuid: ^node_3_uuid, parent_id: nil, prev_id: ^node_1_uuid} = moved_node
    #   assert moved_node == other_moved_node

    #   refute live |> has_element?("#nodes-form-#{node_2.uuid}")
    #   refute other_live |> has_element?("#nodes-form-#{node_2.uuid}")

    #   assert live |> has_element?("#nodes-form-#{node_1.uuid}")
    #   assert other_live |> has_element?("#nodes-form-#{node_1.uuid}")
    # end

    test "delete node", %{
      conn: conn,
      user: user,
      outline_node_container_id: outline_node_container_id,
      stream_id: stream_id,
      nodes: [_node_1, node_2 | _]
    } do
      live = render_live_view(conn, outline_node_container_id, user.id)
      other_live = render_live_view(conn, outline_node_container_id, user.id)

      params = %{"uuid" => node_2.uuid}

      assert live
             |> element(stream_id)
             |> render_hook(:delete, params)

      keep_liveview_alive()

      refute live |> has_element?("#nodes-form-#{node_2.uuid}")
      refute other_live |> has_element?("#nodes-form-#{node_2.uuid}")
    end
  end

  defp keep_liveview_alive do
    :timer.sleep(@additional_keep_alive)
  end

  defp render_live_view(conn, container_id, user_id) do
    session = %{
      "container_id" => container_id,
      "user_id" => user_id
    }

    {:ok, live, _html} =
      live_isolated(conn, OutlineLive.Index, session: session)

    live
  end
end
