defmodule RadiatorWeb.OutlineComponents do
  @moduledoc """
  Provides components for an outline.
  """
  use Phoenix.Component

  alias RadiatorWeb.CoreComponents, as: Core

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  def event_logs(assigns) do
    ~H"""
    <ul id="event_logs" class="" phx-update="stream" phx-page-loading>
      <li :for={{id, event} <- @stream} id={id} class="my-4 border-2 rounded">
        <.event_entry event={event} />
      </li>
    </ul>
    """
  end

  attr :event, :map, required: true

  defp event_entry(%{event: %NodeContentChangedEvent{}} = assigns) do
    ~H"""
    <div class="px-2 bg-gray-200">
      <Core.icon name="hero-pencil-square-solid" class="w-5 h-5" />
      <%= @event.event_id %>
    </div>
    <div class="px-2 ml-8">
      <pre><%= @event.node_id %> - NodeContentChanged</pre>
      <p>content = <%= @event.content %></p>
    </div>
    """
  end

  defp event_entry(%{event: %NodeDeletedEvent{}} = assigns) do
    ~H"""
    <div class="px-2 bg-gray-200">
      <Core.icon name="hero-archive-box-x-mark-solid" class="w-5 h-5" />
      <%= @event.event_id %>
    </div>
    <div class="px-2 ml-8">
      <pre><%= @event.node_id %> - NodeDeleted</pre>
      <p>moved nodes = ?</p>
    </div>
    """
  end

  defp event_entry(%{event: %NodeInsertedEvent{}} = assigns) do
    ~H"""
    <div class="px-2 bg-gray-200">
      <Core.icon name="hero-plus-solid" class="w-5 h-5" />
      <%= @event.event_id %>
    </div>
    <div class="px-2 ml-8">
      <pre><%= @event.node.uuid %> - NodeInserted</pre>
      <p>parent_id = <%= @event.node.parent_id %></p>
      <p>prev_id = <%= @event.node.prev_id %></p>
      <p>content = <%= @event.node.content %></p>
      <p>moved nodes = ?</p>
    </div>
    """
  end

  defp event_entry(%{event: %NodeMovedEvent{}} = assigns) do
    ~H"""
    <div class="px-2 bg-gray-200">
      <Core.icon name="hero-arrows-pointing-out-solid" class="w-5 h-5" />
      <%= @event.event_id %>
    </div>
    <div class="px-2 ml-8">
      <pre><%= @event.node_id %> - NodeMoved</pre>
      <p>parent_id = <%= @event.parent_id %></p>
      <p>prev_id = <%= @event.prev_id %></p>
      <p>moved nodes = ?</p>
    </div>
    """
  end
end
