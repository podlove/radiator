defmodule Radiator.EventStoreFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.EventStore` context.
  """

  @doc """
  Generate a event data.
  """
  def event_data_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        data: %{},
        event_type: "some event_type",
        uuid: "7488a646-e31f-11e4-aace-600308960662"
      })
      |> Radiator.EventStore.create_event_data()

    event
  end
end
