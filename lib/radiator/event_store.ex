defmodule Radiator.EventStore do
  @moduledoc """
  EventStore persists events
  """

  alias Radiator.EventStore.EventData
  alias Radiator.Outline.Event.AbstractEvent
  alias Radiator.Repo

  def persist_event(event) do
    {:ok, _stored_event} =
      create_event_data(%{
        data: AbstractEvent.payload(event),
        event_type: AbstractEvent.event_type(event),
        uuid: event.event_id
      })

    event
  end

  @doc """
  Returns the list of foo_events.

  ## Examples

      iex> list_events()
      [%Event{}, ...]

  """
  def list_event_data do
    Repo.all(EventData)
  end

  @doc """
  Gets a single event data.

  Raises `Ecto.NoResultsError` if the EventData does not exist.

  ## Examples

      iex> get_event_data!(123)
      %Event{}

      iex> get_event_data!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event_data!(id), do: Repo.get!(EventData, id)

  @doc """
  Creates a event.

  ## Examples

      iex> create_event_data(%{field: value})
      {:ok, %EventData{}}

      iex> create_event_data(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event_data(attrs \\ %{}) do
    %EventData{}
    |> EventData.changeset(attrs)
    |> Repo.insert()
  end
end
