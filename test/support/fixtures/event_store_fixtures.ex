defmodule Radiator.EventStoreFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.EventStore` context.
  """
  alias Radiator.AccountsFixtures

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  alias Radiator.OutlineFixtures

  @doc """
  Generate a event data.
  """
  def event_data_fixture(attrs \\ %{}) do
    user = AccountsFixtures.user_fixture()

    {:ok, event} =
      attrs
      |> Enum.into(%{
        data: %{},
        event_type: "some event_type",
        uuid: Ecto.UUID.generate(),
        user_id: user.id
      })
      |> Radiator.EventStore.create_event_data()

    event
  end

  def node_inserted_event_fixture(user_id: user_id) do
    node = OutlineFixtures.node_fixture()

    %NodeInsertedEvent{
      node: node,
      user_id: user_id,
      event_id: Ecto.UUID.generate()
    }
  end

  def node_content_changed_event_fixture(user_id: user_id) do
    node = OutlineFixtures.node_fixture()

    %NodeContentChangedEvent{
      node_id: node.uuid,
      content: node.content,
      user_id: user_id,
      event_id: Ecto.UUID.generate()
    }
  end

  def node_deleted_event_fixture(user_id: user_id) do
    node = OutlineFixtures.node_fixture()

    %NodeDeletedEvent{
      node_id: node.uuid,
      user_id: user_id,
      event_id: Ecto.UUID.generate()
    }
  end

  def node_moved_event_fixture(user_id: user_id) do
    node = OutlineFixtures.node_fixture()
    parent = OutlineFixtures.node_fixture(episode_id: node.episode_id)
    prev = OutlineFixtures.node_fixture(episode_id: node.episode_id)

    %NodeMovedEvent{
      node_id: node.uuid,
      user_id: user_id,
      parent_id: parent.uuid,
      prev_id: prev.uuid,
      event_id: Ecto.UUID.generate()
    }
  end
end
