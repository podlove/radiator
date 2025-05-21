defmodule Radiator.Outline.NodeChangeListener do
  @moduledoc """
  Genserver that listens to change events and starts jobs
  It is an eventconsumer that listens to changes in the outline and starts workers

  Currently actions are hard coded but should be configurable in the future
  """
  use GenServer

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  alias Radiator.Accounts.Raindrop
  alias Radiator.Outline.Dispatch
  alias Radiator.Resources.NodeChangedWorker

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(_) do
    Dispatch.subscribe()
    {:ok, []}
  end

  def handle_info(%NodeContentChangedEvent{node_id: node_id}, state) do
    scan_content_for_urls(node_id)
    {:noreply, state}
  end

  def handle_info(%NodeInsertedEvent{} = event, state) do
    process_system_nodes_if(event)
    {:noreply, state}
  end

  def handle_info(%NodeMovedEvent{} = _event, state) do
    {:noreply, state}
  end

  def handle_info(%NodeDeletedEvent{} = _event, state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _, _}, state) do
    {:noreply, state}
  end

  def handle_info(_reference, state) do
    Logger.warning("Unknown event type")
    {:noreply, state}
  end

  defp scan_content_for_urls(node_id), do: NodeChangedWorker.trigger_analyze(node_id)

  defp process_system_nodes_if(%NodeInsertedEvent{
         user_id: nil,
         node: %{content: "raindrop", container_id: container_id, uuid: raindrop_node_uuid}
       }) do
    show = Radiator.Podcast.get_show_with_inbox_id(container_id)

    case Raindrop.find_user_id_by_show_id(show.id) do
      {:error, :not_found} ->
        Logger.error("User not found for show #{show.id}")

      {:ok, user_id} ->
        Raindrop.set_inbox_node_for_raindrop(
          user_id,
          show.id,
          raindrop_node_uuid
        )
    end

    :ok
  end

  defp process_system_nodes_if(_), do: :ok
end
