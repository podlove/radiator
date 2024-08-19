defmodule RadiatorWeb.EpisodeLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures
  import Radiator.OutlineFixtures

  alias Radiator.Outline
  # alias Radiator.Outline.Node
  # alias Radiator.Outline.NodeRepository

  # @additional_keep_alive 2000

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

    test "create new episode will create node as well", %{conn: conn, show: show} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      live
      |> element(~s{main aside button}, "Create Episode")
      |> render_click()

      submit_live =
        live
        |> form("#episode-form", episode: %{title: "Some new episode"})
        |> render_submit()

      {path, %{"info" => "Episode created successfully"}} = assert_redirect(live)

      episode_id = path |> Path.basename() |> String.to_integer()

      {:ok, new_live, _html} = submit_live |> follow_redirect(conn)

      assert new_live |> has_element?(~s{main h2}, "Some new episode")

      assert_push_event(new_live, "list", %{nodes: [node]})
      %{content: nil, parent_id: nil, prev_id: nil, episode_id: ^episode_id} = node
    end
  end

  describe "Episode outline nodes" do
    setup %{conn: conn} do
      user = user_fixture()
      show = show_fixture()
      episode = episode_fixture(%{show_id: show.id})

      node_1 =
        node_fixture(
          episode_id: episode.id,
          parent_id: nil,
          prev_id: nil,
          content: "node_1"
        )

      node_3 =
        node_fixture(
          episode_id: episode.id,
          parent_id: node_1.uuid,
          prev_id: nil,
          content: "node_3"
        )

      node_2 =
        node_fixture(
          episode_id: episode.id,
          parent_id: node_1.uuid,
          prev_id: node_3.uuid,
          content: "node_2"
        )

      Outline.move_node(node_3.uuid, node_2.uuid, node_1.uuid)

      %{conn: log_in_user(conn, user), show: show, episode: episode, nodes: [node_3, node_2]}
    end

    test "lists all nodes", %{conn: conn, show: show, episode: episode} do
      {:ok, live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      nodes =
        episode.id
        |> Outline.list_nodes_by_episode_sorted()

      assert_push_event(live, "list", %{nodes: ^nodes})
    end

    test "insert a new node", %{conn: conn, show: show, nodes: [node | _]} do
      {:ok, _live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
      {:ok, _other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      uuid = Ecto.UUID.generate()

      _params = %{
        "uuid" => uuid,
        "content" => "new node content",
        "prev_id" => node.uuid
      }

      # assert live |> render_hook(:create_node, params)

      # keep_liveview_alive()

      # assert %Node{} = new_node = NodeRepository.get_node!(uuid)
      # assert new_node.uuid == uuid
      # assert new_node.parent_id == nil
      # assert new_node.prev_id == node.uuid

      # assert_push_event(live, "clean", %{node: %{uuid: ^uuid}})
      # assert_push_event(other_live, "insert", %{node: ^new_node})
    end

    test "update node content", %{conn: conn, show: show, nodes: [%{uuid: uuid} | _]} do
      {:ok, _live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
      {:ok, _other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      content = "updated node content"
      _params = %{"uuid" => uuid, "content" => content}

      # assert live |> render_hook(:update_node_content, params)

      # keep_liveview_alive()

      # assert %Node{content: ^content} = NodeRepository.get_node!(uuid)

      # assert_push_event(live, "clean", %{node: %{uuid: ^uuid}})
      # assert_push_event(other_live, "change_content", %{node: %{uuid: ^uuid, content: ^content}})
    end

    test "move node", %{conn: conn, show: show, episode: episode, nodes: [node_1 | _]} do
      %{uuid: uuid1, parent_id: parent_id1} = node_1

      uuid2 = Ecto.UUID.generate()

      node2 =
        node_fixture(%{
          uuid: uuid2,
          episode_id: episode.id,
          parent_id: parent_id1,
          prev_id: uuid1
        })

      {:ok, _live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
      {:ok, _other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      _params = node2 |> Map.merge(%{parent_id: uuid1, prev_id: nil}) |> Map.from_struct()

      # assert live |> render_hook(:move_node, params)

      # keep_liveview_alive()

      # assert %Node{parent_id: ^uuid1} = NodeRepository.get_node!(uuid2)

      # assert_push_event(live, "clean", %{node: %{uuid: ^uuid2}})

      # assert_push_event(other_live, "move", %{
      #   node: %{uuid: ^uuid2, parent_id: ^uuid1, prev_id: nil}
      # })
    end

    test "delete node", %{conn: conn, show: show, nodes: [%{uuid: uuid} | _]} do
      {:ok, _live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")
      {:ok, _other_live, _html} = live(conn, ~p"/admin/podcast/#{show.id}")

      _params = %{"uuid" => uuid}

      # assert live |> render_hook(:delete_node, params)

      # keep_liveview_alive()

      # assert NodeRepository.get_node(uuid) == nil

      # assert_push_event(live, "clean", %{node: %{uuid: ^uuid}})
      # assert_push_event(other_live, "delete", %{node: %{uuid: ^uuid}})
    end
  end

  # defp keep_liveview_alive do
  #   :timer.sleep(@additional_keep_alive)
  # end
end
