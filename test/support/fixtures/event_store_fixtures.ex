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
    next = OutlineFixtures.node_fixture(episode_id: node.episode_id)

    %NodeInsertedEvent{
      node: node,
      user_id: user_id,
      event_id: Ecto.UUID.generate(),
      next: next
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
      node: node,
      user_id: user_id,
      event_id: Ecto.UUID.generate()
    }
  end

  def node_moved_event_fixture(user_id: user_id) do
    node = OutlineFixtures.node_fixture()
    _parent = OutlineFixtures.node_fixture(episode_id: node.episode_id)
    _prev = OutlineFixtures.node_fixture(episode_id: node.episode_id)
    next = OutlineFixtures.node_fixture(episode_id: node.episode_id)
    old_next = OutlineFixtures.node_fixture(episode_id: node.episode_id)

    old_prev =
      OutlineFixtures.node_fixture(episode_id: node.episode_id)

    %NodeMovedEvent{
      node: %{uuid: node.uuid, parent_id: node.parent_id, prev_id: node.prev_id},
      user_id: user_id,
      next: next,
      old_next: old_next,
      old_prev: old_prev,
      event_id: Ecto.UUID.generate()
    }
  end
end
