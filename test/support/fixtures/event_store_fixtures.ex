defmodule Radiator.EventStoreFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.EventStore` context.
  """
  alias Radiator.AccountsFixtures

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
end
