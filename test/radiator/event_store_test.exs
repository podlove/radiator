defmodule Radiator.EventStoreTest do
  use Radiator.DataCase

  alias Radiator.EventStore

  describe "event_data" do
    alias Radiator.EventStore.EventData

    alias Radiator.AccountsFixtures
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

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = EventStore.create_event_data(@invalid_attrs)
    end
  end
end
