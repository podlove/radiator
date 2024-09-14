defmodule Radiator.WebTest do
  use Radiator.DataCase

  import Ecto.Query, warn: false

  alias Radiator.Web
  alias Radiator.Web.Url
  import Radiator.WebFixtures

  describe "urls" do
    @invalid_attrs %{url: nil, start_bytes: nil, size_bytes: nil}

    test "list_urls/0 returns all urls" do
      url = url_fixture()
      assert Web.list_urls() == [url]
    end

    test "get_url!/1 returns the url with given id" do
      url = url_fixture()
      assert Web.get_url!(url.id) == url
    end

    test "create_url/1 with valid data creates a url" do
      valid_attrs = %{url: "some url", start_bytes: 42, size_bytes: 42}

      assert {:ok, %Url{} = url} = Web.create_url(valid_attrs)
      assert url.url == "some url"
      assert url.start_bytes == 42
      assert url.size_bytes == 42
    end

    test "create_url/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Web.create_url(@invalid_attrs)
    end

    test "update_url/2 with valid data updates the url" do
      url = url_fixture()
      update_attrs = %{url: "some updated url", start_bytes: 43, size_bytes: 43}

      assert {:ok, %Url{} = url} = Web.update_url(url, update_attrs)
      assert url.url == "some updated url"
      assert url.start_bytes == 43
      assert url.size_bytes == 43
    end

    test "update_url/2 with invalid data returns error changeset" do
      url = url_fixture()
      assert {:error, %Ecto.Changeset{}} = Web.update_url(url, @invalid_attrs)
      assert url == Web.get_url!(url.id)
    end

    test "delete_url/1 deletes the url" do
      url = url_fixture()
      assert {:ok, %Url{}} = Web.delete_url(url)
      assert_raise Ecto.NoResultsError, fn -> Web.get_url!(url.id) end
    end

    test "change_url/1 returns a url changeset" do
      url = url_fixture()
      assert %Ecto.Changeset{} = Web.change_url(url)
    end
  end
end
