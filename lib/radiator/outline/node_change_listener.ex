defmodule Radiator.Outline.NodeChangeListener do
  @moduledoc """
  Genserver that listens to change events and starts jobs
  It is an eventconsumer that listens to changes in the outline and starts workers
  """
  use GenServer

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  alias Radiator.Outline.Dispatch
  alias Radiator.Web
  alias Radiator.Web.UrlExtractor

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(_) do
    Dispatch.subscribe()
    {:ok, []}
  end

  def handle_info(%NodeContentChangedEvent{node_id: node_id, content: content}, state) do
    scan_content_for_urls(node_id, content)
    {:noreply, state}
  end

  def handle_info(%NodeInsertedEvent{} = _event, state) do
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

  defp scan_content_for_urls(_node_id, nil), do: nil

  defp scan_content_for_urls(node_id, content) do
    Task.async(fn ->
      result = UrlExtractor.extract_urls(content)

      # TODO - handle old existing urls for this node, error handling!
      Enum.each(result, fn info ->
        {:ok, _url} =
          info
          |> Map.put(:node_id, node_id)
          |> Map.put(:url, info.parsed_url)
          |> Web.create_url()
      end)
    end)
  end
end
