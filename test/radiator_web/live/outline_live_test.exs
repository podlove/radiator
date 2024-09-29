defmodule RadiatorWeb.OutlineLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures
  import Radiator.OutlineFixtures

  # alias Radiator.Outline
  # alias Radiator.Outline.NodeRepository

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

      node_3 =
        node_fixture(
          episode_id: episode_id,
          parent_id: nil,
          prev_id: node_2.uuid,
          content: "node_3"
        )

      %{conn: log_in_user(conn, user), show_id: show_id, nodes: [node_1, node_2, node_3]}
    end

    test "lists all nodes", %{conn: conn, show_id: show_id, nodes: [node_1, node_2, node_3]} do
      {:ok, _live, html} = live(conn, ~p"/admin/podcast/#{show_id}")

      assert html =~ node_1.content
      assert html =~ node_2.content
      assert html =~ node_3.content
    end

    test "update node content", %{conn: conn, show_id: show_id, nodes: [%{uuid: uuid} | _]} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")
      {:ok, other_live, _other_html} = live(conn, ~p"/admin/podcast/#{show_id}")

      assert live
             |> form("#form-#{uuid}", node: %{content: "node_1_updated"})
             |> render_change()

      keep_liveview_alive()

      assert_push_event(live, "set_content", %{uuid: ^uuid, content: "node_1_updated"})
      assert_push_event(other_live, "set_content", %{uuid: ^uuid, content: "node_1_updated"})
    end

    test "insert a new node", %{conn: conn, show_id: show_id, nodes: [_, %{uuid: uuid} | _]} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")
      {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")

      assert live
             |> element("#form-#{uuid}_content")
             |> render_keydown(%{"key" => "Enter", "selection" => %{"start" => 2, "end" => 2}})

      keep_liveview_alive()

      assert_push_event(live, "set_content", %{uuid: ^uuid, content: "no"})
      assert_push_event(other_live, "set_content", %{uuid: ^uuid, content: "no"})

      assert live |> has_element?("[value=de_2]")
      assert other_live |> has_element?("[value=de_2]")
    end

    # test "move node", %{conn: conn, show: show, episode: episode, nodes: [node_1 | _]} do
    #   %{uuid: uuid1, parent_id: parent_id1} = node_1

    #   uuid2 = Ecto.UUID.generate()

    #   node2 =
    #     node_fixture(%{
    #       uuid: uuid2,
    #       episode_id: episode.id,
    #       parent_id: parent_id1,
    #       prev_id: uuid1
    #     })

    #   {:ok, _live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
    #   {:ok, _other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

    #   _params = node2 |> Map.merge(%{parent_id: uuid1, prev_id: nil}) |> Map.from_struct()

    #   # assert live |> render_hook(:move_node, params)

    #   # keep_liveview_alive()

    #   # assert %Node{parent_id: ^uuid1} = NodeRepository.get_node!(uuid2)

    #   # assert_push_event(live, "clean", %{node: %{uuid: ^uuid2}})

    #   # assert_push_event(other_live, "move", %{
    #   #   node: %{uuid: ^uuid2, parent_id: ^uuid1, prev_id: nil}
    #   # })
    # end

    test "delete node", %{conn: conn, show_id: show_id, nodes: [_, _, node_3]} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")
      {:ok, other_live, _html} = live(conn, ~p"/admin/podcast/#{show_id}")

      assert live
             |> element("#form-#{node_3.uuid}_content")
             |> render_keydown(%{"key" => "Delete", "value" => ""})

      keep_liveview_alive()

      refute live |> has_element?("#form-#{node_3.uuid}")
      refute other_live |> has_element?("#form-#{node_3.uuid}")
    end
  end

  defp keep_liveview_alive do
    :timer.sleep(@additional_keep_alive)
  end
end
