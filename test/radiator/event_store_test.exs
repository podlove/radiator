defmodule Radiator.EventStoreTest do
  use Radiator.DataCase

  alias Radiator.EventStore
  alias Radiator.EventStore.EventData

  alias Radiator.AccountsFixtures
  import Radiator.EventStoreFixtures

  describe "persist_event/1" do
    test "persists node_inserted_event" do
      user = AccountsFixtures.user_fixture()
      event = node_inserted_event_fixture(user_id: user.id)

      num_events = EventStore.list_event_data() |> length()
      EventStore.persist_event(event)
      assert EventStore.list_event_data() |> length() == num_events + 1
    end

    test "persists node_content_changed_event" do
      user = AccountsFixtures.user_fixture()
      event = node_content_changed_event_fixture(user_id: user.id)

      num_events = EventStore.list_event_data() |> length()
      EventStore.persist_event(event)
      assert EventStore.list_event_data() |> length() == num_events + 1
    end

    test "persists node_deleted_event" do
      user = AccountsFixtures.user_fixture()
      event = node_deleted_event_fixture(user_id: user.id)

      num_events = EventStore.list_event_data() |> length()
      EventStore.persist_event(event)
      assert EventStore.list_event_data() |> length() == num_events + 1
    end

    test "persists node_moved_event" do
      user = AccountsFixtures.user_fixture()
      event = node_moved_event_fixture(user_id: user.id)

      num_events = EventStore.list_event_data() |> length()
      EventStore.persist_event(event)
      assert EventStore.list_event_data() |> length() == num_events + 1
    end
  end

  describe "list_event_data/0" do
    test "returns all event_data" do
      event = event_data_fixture()
      assert EventStore.list_event_data() == [event]
    end
  end

  describe "get_event_data!/1" do
    test "returns the event_data with given id" do
      event = event_data_fixture()
      assert EventStore.get_event_data!(event.uuid) == event
    end
  end

  describe "create_event_data/1" do
    test " with valid data creates a event" do
      user = AccountsFixtures.user_fixture()

      valid_attrs = %{
        data: %{},
        uuid: Ecto.UUID.generate(),
        event_type: "some event_type",
        user_id: user.id
      }

      assert {:ok, %EventData{} = event} = EventStore.create_event_data(valid_attrs)
      assert event.data == %{}
      assert event.uuid == valid_attrs.uuid
      assert event.event_type == valid_attrs.event_type
      assert event.user_id == valid_attrs.user_id
    end

    test "with invalid data returns error changeset" do
      invalid_attrs = %{data: nil, uuid: nil, event_type: nil}
      assert {:error, %Ecto.Changeset{}} = EventStore.create_event_data(invalid_attrs)
    end
  end
end
