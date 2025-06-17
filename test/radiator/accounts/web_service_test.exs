defmodule Radiator.Accounts.WebServiceTest do
  use Radiator.DataCase, async: false

  import Radiator.AccountsFixtures
  alias Radiator.Accounts.Raindrop
  alias Radiator.Accounts.WebService
  alias Radiator.PodcastFixtures
  alias Radiator.Repo

  describe "get_raindrop_tokens/1" do
    setup do
      %{web_service: raindrop_service_fixture()}
    end

    test "returns the raindrop tokens", %{web_service: web_service} do
      fetched_web_service = Raindrop.get_raindrop_tokens(web_service.user_id)
      assert fetched_web_service.data == web_service.data
    end
  end

  describe "update_raindrop_tokens/4" do
    setup do
      user = user_fixture()

      web_service = %{
        user_id: user.id,
        access_token: "ae261404-11r4-47c0-bce3-e18a423da828",
        refresh_token: "c8080368-fad2-4a3f-b2c9-71d3z85011vb",
        expires_at:
          DateTime.utc_now() |> DateTime.shift(second: 1_209_599) |> DateTime.truncate(:second)
      }

      %{user: user, web_service: web_service}
    end

    test "creates a new entry if none exists", %{user: user, web_service: web_service} do
      count_before = Repo.aggregate(WebService, :count)

      Raindrop.update_raindrop_tokens(
        user.id,
        web_service.access_token,
        web_service.refresh_token,
        web_service.expires_at
      )

      count_after = Repo.aggregate(WebService, :count)
      assert count_after == count_before + 1

      %WebService{} = service = Raindrop.get_raindrop_tokens(user.id)

      assert service.data.access_token == web_service.access_token
      assert service.data.refresh_token == web_service.refresh_token
      assert service.data.expires_at == web_service.expires_at
    end

    test "updates the raindrop tokens", %{user: user, web_service: web_service} do
      # Create a new entry
      Raindrop.update_raindrop_tokens(
        user.id,
        web_service.access_token,
        web_service.refresh_token,
        web_service.expires_at
      )

      count_before = Repo.aggregate(WebService, :count)
      # Update the entry, must not create a new one
      Raindrop.update_raindrop_tokens(
        user.id,
        "new-access-token",
        "new-refresh-token",
        web_service.expires_at
      )

      count_after = Repo.aggregate(WebService, :count)
      assert count_after == count_before

      %WebService{} = service = Raindrop.get_raindrop_tokens(user.id)
      assert service.data.access_token == "new-access-token"
      assert service.data.refresh_token == "new-refresh-token"
    end
  end

  describe "connect_show_with_rainbow/3" do
    setup do
      %{web_service: raindrop_service_fixture(), show: PodcastFixtures.show_fixture()}
    end

    test "saves a show - collection connection in collection_mappings", %{
      web_service: web_service,
      show: show
    } do
      Raindrop.connect_show_with_raindrop(web_service.user_id, show.id, 42)

      service = Raindrop.get_raindrop_tokens(web_service.user_id)

      assert Enum.map(service.data.mappings, &Map.from_struct/1) == [
               %{collection_id: 42, node_id: nil, show_id: show.id}
             ]
    end

    test "can add multiple shows", %{
      web_service: web_service,
      show: show
    } do
      Raindrop.connect_show_with_raindrop(web_service.user_id, show.id, 42)

      second_show = PodcastFixtures.show_fixture()
      third_show = PodcastFixtures.show_fixture()

      Raindrop.connect_show_with_raindrop(web_service.user_id, second_show.id, 23)
      Raindrop.connect_show_with_raindrop(web_service.user_id, third_show.id, 666)

      service = Raindrop.get_raindrop_tokens(web_service.user_id)

      assert Enum.map(service.data.mappings, &Map.from_struct/1) == [
               %{collection_id: 42, node_id: nil, show_id: show.id},
               %{node_id: nil, show_id: second_show.id, collection_id: 23},
               %{node_id: nil, show_id: third_show.id, collection_id: 666}
             ]
    end

    test "can override show", %{
      web_service: web_service,
      show: show
    } do
      Raindrop.connect_show_with_raindrop(web_service.user_id, show.id, 42)

      Raindrop.connect_show_with_raindrop(web_service.user_id, show.id, 23)
      service = Raindrop.get_raindrop_tokens(web_service.user_id)

      assert Enum.map(service.data.mappings, &Map.from_struct/1) == [
               %{collection_id: 23, node_id: nil, show_id: show.id}
             ]
    end
  end

  describe "set_inbox_node_for_raindrop/3" do
    setup do
      %{web_service: raindrop_service_fixture(), show: PodcastFixtures.show_fixture()}
    end

    test "sets a node_id for a show while preserving the collection_id", %{
      web_service: web_service,
      show: show
    } do
      # First connect a show with a collection
      {:ok, _} = Raindrop.connect_show_with_raindrop(web_service.user_id, show.id, 42)

      # Now set a node_id for this show
      node_id = Ecto.UUID.generate()
      {:ok, _} = Raindrop.set_inbox_node_for_raindrop(web_service.user_id, show.id, node_id)

      # Get the updated service and check
      service = Raindrop.get_raindrop_tokens(web_service.user_id)

      mappings = Enum.map(service.data.mappings, &Map.from_struct/1)
      assert length(mappings) == 1
      mapping = List.first(mappings)
      assert mapping.collection_id == 42
      assert mapping.node_id == node_id
      assert mapping.show_id == show.id
    end

    test "sets a node_id for a show without existing collection_id", %{
      web_service: web_service,
      show: show
    } do
      # Set a node_id directly without first creating a mapping
      node_id = Ecto.UUID.generate()
      {:ok, _} = Raindrop.set_inbox_node_for_raindrop(web_service.user_id, show.id, node_id)

      # Get the updated service and check
      service = Raindrop.get_raindrop_tokens(web_service.user_id)

      mappings = Enum.map(service.data.mappings, &Map.from_struct/1)
      assert length(mappings) == 1
      mapping = List.first(mappings)
      assert mapping.collection_id == nil
      assert mapping.node_id == node_id
      assert mapping.show_id == show.id
    end

    test "returns an error when no raindrop tokens are found", %{
      show: show
    } do
      # Use a non-existent user ID
      non_existent_user_id = 999_999
      node_id = Ecto.UUID.generate()

      result = Raindrop.set_inbox_node_for_raindrop(non_existent_user_id, show.id, node_id)

      assert result == {:error, "No Raindrop tokens found"}
    end
  end

  describe "WebService model" do
    test "creates a valid web service" do
      user = user_fixture()

      attrs = %{
        service_name: "raindrop",
        user_id: user.id,
        data: %{
          access_token: "test-token",
          refresh_token: "test-refresh",
          expires_at: DateTime.utc_now() |> DateTime.shift(hour: 1) |> DateTime.truncate(:second),
          mappings: []
        }
      }

      changeset = WebService.changeset(%WebService{}, attrs)
      assert changeset.valid?

      {:ok, service} = Repo.insert(changeset)
      assert service.service_name == "raindrop"
      assert service.user_id == user.id
      assert service.data.access_token == "test-token"
    end

    test "requires service_name, user_id, and data" do
      changeset = WebService.changeset(%WebService{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).service_name
      assert "can't be blank" in errors_on(changeset).user_id
      assert "can't be blank" in errors_on(changeset).data
    end

    test "validates service_name is in allowed types" do
      user = user_fixture()

      attrs = %{
        service_name: "invalid_service",
        user_id: user.id,
        data: %{
          access_token: "test-token",
          refresh_token: "test-refresh",
          expires_at: DateTime.utc_now() |> DateTime.shift(hour: 1) |> DateTime.truncate(:second),
          mappings: []
        }
      }

      changeset = WebService.changeset(%WebService{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).service_name
    end

    test "validates last_sync cannot be in the future" do
      user = user_fixture()
      future_time = DateTime.utc_now() |> DateTime.shift(hour: 1) |> DateTime.truncate(:second)

      attrs = %{
        service_name: "raindrop",
        user_id: user.id,
        last_sync: future_time,
        data: %{
          access_token: "test-token",
          refresh_token: "test-refresh",
          expires_at: DateTime.utc_now() |> DateTime.shift(hour: 2) |> DateTime.truncate(:second),
          mappings: []
        }
      }

      changeset = WebService.changeset(%WebService{}, attrs)
      refute changeset.valid?
      assert "cannot be in the future" in errors_on(changeset).last_sync
    end

    test "allows last_sync to be nil" do
      user = user_fixture()

      attrs = %{
        service_name: "raindrop",
        user_id: user.id,
        last_sync: nil,
        data: %{
          access_token: "test-token",
          refresh_token: "test-refresh",
          expires_at: DateTime.utc_now() |> DateTime.shift(hour: 1) |> DateTime.truncate(:second),
          mappings: []
        }
      }

      changeset = WebService.changeset(%WebService{}, attrs)
      assert changeset.valid?
    end

    test "allows last_sync to be in the past or present" do
      user = user_fixture()
      past_time = DateTime.utc_now() |> DateTime.shift(hour: -1) |> DateTime.truncate(:second)

      attrs = %{
        service_name: "raindrop",
        user_id: user.id,
        last_sync: past_time,
        data: %{
          access_token: "test-token",
          refresh_token: "test-refresh",
          expires_at: DateTime.utc_now() |> DateTime.shift(hour: 1) |> DateTime.truncate(:second),
          mappings: []
        }
      }

      changeset = WebService.changeset(%WebService{}, attrs)
      assert changeset.valid?
    end
  end

  describe "update_last_sync/2" do
    test "updates last_sync with current time when no time provided" do
      service = web_service_fixture()

      changeset = WebService.update_last_sync(service)

      assert changeset.valid?
      last_sync = get_change(changeset, :last_sync)
      assert last_sync != nil
      # Should be within the last few seconds
      assert DateTime.diff(DateTime.utc_now(), last_sync, :second) < 5
    end

    test "updates last_sync with provided time" do
      service = web_service_fixture()
      sync_time = DateTime.utc_now() |> DateTime.shift(hour: -1) |> DateTime.truncate(:second)

      changeset = WebService.update_last_sync(service, sync_time)

      assert changeset.valid?
      assert get_change(changeset, :last_sync) == sync_time
    end

    test "fails validation when provided time is in the future" do
      service = web_service_fixture()
      future_time = DateTime.utc_now() |> DateTime.shift(hour: 1) |> DateTime.truncate(:second)

      changeset = WebService.update_last_sync(service, future_time)

      refute changeset.valid?
      assert "cannot be in the future" in errors_on(changeset).last_sync
    end

    test "can be used to persist last_sync to database" do
      service = web_service_fixture()
      sync_time = DateTime.utc_now() |> DateTime.shift(minute: -30) |> DateTime.truncate(:second)

      changeset = WebService.update_last_sync(service, sync_time)
      {:ok, updated_service} = Repo.update(changeset)

      assert updated_service.last_sync == sync_time
    end
  end

  describe "web_service_fixture/1" do
    test "creates a web service with default values" do
      service = web_service_fixture()

      assert service.service_name == "raindrop"
      assert service.user_id != nil
      assert service.data.access_token != nil
      assert service.data.refresh_token != nil
      assert service.data.expires_at != nil
      assert service.data.mappings == []
      assert service.last_sync == nil
    end

    test "creates a web service with custom last_sync" do
      sync_time = DateTime.utc_now() |> DateTime.shift(hour: -2) |> DateTime.truncate(:second)
      service = web_service_fixture(last_sync: sync_time)

      assert service.last_sync == sync_time
    end

    test "creates a web service with custom user" do
      user = user_fixture(email: "custom@example.com")
      service = web_service_fixture(user: user)

      assert service.user_id == user.id
    end
  end
end
