defmodule Radiator.EventStoreTest do
  use Radiator.DataCase

  alias Radiator.EventStore

  describe "event_data" do
    alias Radiator.EventStore.EventData

    import Radiator.EventStoreFixtures

    @invalid_attrs %{data: nil, uuid: nil, event_type: nil}

    test "list_event_data/0 returns all event_data" do
      event = event_data_fixture()
      assert EventStore.list_event_data() == [event]
    end

    test "get_event!/1 returns the event_data with given id" do
      event = event_data_fixture()
      assert EventStore.get_event_data!(event.uuid) == event
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{
        data: %{},
        uuid: "7488a646-e31f-11e4-aace-600308960662",
        event_type: "some event_type"
      }

      assert {:ok, %EventData{} = event} = EventStore.create_event_data(valid_attrs)
      assert event.data == %{}
      assert event.uuid == "7488a646-e31f-11e4-aace-600308960662"
      assert event.event_type == "some event_type"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = EventStore.create_event_data(@invalid_attrs)
    end
  end
end
