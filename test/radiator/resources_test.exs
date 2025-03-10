defmodule Radiator.ResourcesbTest do
  use Radiator.DataCase

  import Ecto.Query, warn: false
  import Radiator.ResourcesFixtures

  alias Radiator.OutlineFixtures
  alias Radiator.PodcastFixtures
  alias Radiator.Resources
  alias Radiator.Resources.Url

  @invalid_attrs %{url: nil, start_bytes: nil, size_bytes: nil}

  describe "list_urls_by_episode/0" do
    setup :set_up_single_url

    test "returns all urls of an episode", %{episode: episode, node: node} do
      url = url_fixture(node_id: node.uuid, episode_id: episode.id)
      assert Resources.list_urls_by_episode(episode.id) == [url]
    end
  end

  describe "get_url!/1" do
    setup :set_up_single_url

    test "get_url!/1 returns the url with given id" do
      url = url_fixture()
      assert Resources.get_url!(url.id) == url
    end
  end

  describe "create_url!/1" do
    setup :set_up_single_url

    test "creates a url with valid data", %{node: node} do
      valid_attrs = %{url: "some url", start_bytes: 42, size_bytes: 42, node_id: node.uuid}

      assert {:ok, %Url{} = url} = Resources.create_url(valid_attrs)
      assert url.url == "some url"
      assert url.start_bytes == 42
      assert url.size_bytes == 42
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Resources.create_url(@invalid_attrs)
    end
  end

  describe "rebuild_node_urls/2" do
    setup :set_up_single_url

    test "rebuilds all urls for a node" do
      url_text = "https://hexdocs.pm"
      episode = PodcastFixtures.episode_fixture()

      node =
        OutlineFixtures.node_fixture(container_id: episode.outline_node_container_id)

      old_url = url_fixture(node_id: node.uuid)
      episode_id = episode.id

      assert [%Url{url: ^url_text, start_bytes: 42, size_bytes: 42, episode_id: ^episode_id}] =
               Resources.rebuild_node_urls(node.uuid, [
                 %{
                   url: url_text,
                   start_bytes: 42,
                   size_bytes: 42,
                   node_id: node.uuid,
                   episode_id: episode_id
                 }
               ])

      assert_raise Ecto.NoResultsError, fn -> Resources.get_url!(old_url.id) end
    end
  end

  describe "update_url/2" do
    setup :set_up_single_url

    test "with valid data updates the url" do
      url = url_fixture()
      update_attrs = %{url: "some updated url", start_bytes: 43, size_bytes: 43}

      assert {:ok, %Url{} = url} = Resources.update_url(url, update_attrs)
      assert url.url == "some updated url"
      assert url.start_bytes == 43
      assert url.size_bytes == 43
    end

    test "with invalid data returns error changeset" do
      url = url_fixture()
      assert {:error, %Ecto.Changeset{}} = Resources.update_url(url, @invalid_attrs)
      assert url == Resources.get_url!(url.id)
    end
  end

  describe "delete_url/1" do
    test " deletes the url" do
      url = url_fixture()
      assert {:ok, %Url{}} = Resources.delete_url(url)
      assert_raise Ecto.NoResultsError, fn -> Resources.get_url!(url.id) end
    end
  end

  describe "delete_urls_for_node/1" do
    test "deletes all urls from a node" do
      node = OutlineFixtures.node_fixture()
      url = url_fixture(node_id: node.uuid)

      assert 1 = Resources.delete_urls_for_node(node)
      assert_raise Ecto.NoResultsError, fn -> Resources.get_url!(url.id) end
    end
  end

  describe "change_url/1" do
    test "returns a url changeset" do
      url = url_fixture()
      assert %Ecto.Changeset{} = Resources.change_url(url)
    end
  end

  def set_up_single_url(_) do
    episode = PodcastFixtures.episode_fixture()

    node =
      OutlineFixtures.node_fixture(container_id: episode.outline_node_container_id)

    {:ok, episode: episode, node: node}
  end
end
