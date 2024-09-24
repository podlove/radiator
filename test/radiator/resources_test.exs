defmodule Radiator.ResourcesbTest do
  use Radiator.DataCase

  import Ecto.Query, warn: false
  import Radiator.ResourcesFixtures

  alias Radiator.OutlineFixtures
  alias Radiator.Resources
  alias Radiator.Resources.Url

  describe "urls" do
    setup do
      node =
        OutlineFixtures.node_fixture()
        |> Repo.preload([:episode])

      episode = node.episode

      %{
        episode: episode,
        node: node
      }
    end

    @invalid_attrs %{url: nil, start_bytes: nil, size_bytes: nil}

    test "list_urls/0 returns all urls", %{episode: episode, node: node} do
      url = url_fixture(node_id: node.uuid)
      assert Resources.list_urls(episode.id) == [url]
    end

    test "get_url!/1 returns the url with given id" do
      url = url_fixture()
      assert Resources.get_url!(url.id) == url
    end

    test "create_url/1 with valid data creates a url", %{node: node} do
      valid_attrs = %{url: "some url", start_bytes: 42, size_bytes: 42, node_id: node.uuid}

      assert {:ok, %Url{} = url} = Resources.create_url(valid_attrs)
      assert url.url == "some url"
      assert url.start_bytes == 42
      assert url.size_bytes == 42
    end

    test "create_url/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Resources.create_url(@invalid_attrs)
    end

    test "update_url/2 with valid data updates the url" do
      url = url_fixture()
      update_attrs = %{url: "some updated url", start_bytes: 43, size_bytes: 43}

      assert {:ok, %Url{} = url} = Resources.update_url(url, update_attrs)
      assert url.url == "some updated url"
      assert url.start_bytes == 43
      assert url.size_bytes == 43
    end

    test "update_url/2 with invalid data returns error changeset" do
      url = url_fixture()
      assert {:error, %Ecto.Changeset{}} = Resources.update_url(url, @invalid_attrs)
      assert url == Resources.get_url!(url.id)
    end

    test "delete_url/1 deletes the url" do
      url = url_fixture()
      assert {:ok, %Url{}} = Resources.delete_url(url)
      assert_raise Ecto.NoResultsError, fn -> Resources.get_url!(url.id) end
    end

    test "change_url/1 returns a url changeset" do
      url = url_fixture()
      assert %Ecto.Changeset{} = Resources.change_url(url)
    end
  end
end
