defmodule RadiatorWeb.OutlineComponents do
  @moduledoc """
  Provides components for an outline.
  """
  use Phoenix.Component

  alias RadiatorWeb.CoreComponents, as: Core

  alias Radiator.Outline

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  @doc """
  Renders an outline form.

  ## Examples

      <.outline_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.outline_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def outline_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="flex items-center justify-between gap-6 mt-2">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders the keyboard shortcuts.

  ## Examples

      <.keyboard_shortcuts />
  """
  def keyboard_shortcuts(assigns) do
    ~H"""
    <aside>
      <h3 class="text-base font-semibold leading-7 text-gray-600">Shortcuts</h3>
      <dl class="divide-y divide-gray-100">
        <div class="grid grid-cols-3 gap-4 px-0 py-2">
          <dt class="text-sm font-medium leading-6 text-gray-600">Add note</dt>
          <dd class="col-span-2 mt-0 text-sm leading-6 text-gray-700">
            ↵
          </dd>
        </div>
        <div class="grid grid-cols-3 gap-4 px-0 py-2">
          <dt class="text-sm font-medium leading-6 text-gray-600">Cursor up</dt>
          <dd class="col-span-2 mt-0 text-sm leading-6 text-gray-700">
            ↑
          </dd>
        </div>
        <div class="grid grid-cols-3 gap-4 px-0 py-2">
          <dt class="text-sm font-medium leading-6 text-gray-600">Cursor down</dt>
          <dd class="col-span-2 mt-0 text-sm leading-6 text-gray-700">
            ↓
          </dd>
        </div>
        <div class="grid grid-cols-3 gap-4 px-0 py-2">
          <dt class="text-sm font-medium leading-6 text-gray-600">Indent</dt>
          <dd class="col-span-2 mt-0 text-sm leading-6 text-gray-700">
            ⇥
          </dd>
        </div>
        <div class="grid grid-cols-3 gap-4 px-0 py-2">
          <dt class="text-sm font-medium leading-6 text-gray-600">Outdent</dt>
          <dd class="col-span-2 mt-0 text-sm leading-6 text-gray-700">
            ⇧⇥
          </dd>
        </div>
        <div class="grid grid-cols-3 gap-4 px-0 py-2">
          <dt class="text-sm font-medium leading-6 text-gray-600">Collapse</dt>
          <dd class="col-span-2 mt-0 text-sm leading-6 text-gray-700"></dd>
        </div>
        <div class="grid grid-cols-3 gap-4 px-0 py-2">
          <dt class="text-sm font-medium leading-6 text-gray-600">Expand</dt>
          <dd class="col-span-2 mt-0 text-sm leading-6 text-gray-700"></dd>
        </div>
        <div class="grid grid-cols-3 gap-4 px-0 py-2">
          <dt class="text-sm font-medium leading-6 text-gray-600">Move node up</dt>
          <dd class="col-span-2 mt-0 text-sm leading-6 text-gray-700">⌥↑</dd>
        </div>
        <div class="grid grid-cols-3 gap-4 px-0 py-2">
          <dt class="text-sm font-medium leading-6 text-gray-600">Move node down</dt>
          <dd class="col-span-2 mt-0 text-sm leading-6 text-gray-700">⌥↓</dd>
        </div>
      </dl>
    </aside>
    """
  end

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
      <pre><%= @event.node.uuid %> - NodeDeleted</pre>
      <p>next node = ?</p>
      <p>child nodes = ?</p>
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
      <p>next_id = <%= Outline.get_node_id(@event.next) %></p>
      <p>content = <%= @event.node.content %></p>
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
      <pre><%= @event.node.uuid %> - NodeMoved</pre>
      <p>parent_id = <%= @event.node.parent_id %></p>
      <p>prev_id = <%= @event.node.prev_id %></p>
      <p>old_prev_id = <%= Outline.get_node_id(@event.old_prev) %></p>
      <p>old_next_id = <%= Outline.get_node_id(@event.old_next) %></p>
      <p>next_id = <%= Outline.get_node_id(@event.next) %></p>
    </div>
    """
  end
end
