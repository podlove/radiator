defmodule RadiatorWeb.OutlineComponents do
  @moduledoc """
  Provides components for an outline.
  """
  use Phoenix.Component

  alias Phoenix.HTML
  alias Phoenix.LiveView.JS

  alias RadiatorWeb.CoreComponents, as: Core

  alias Radiator.Outline

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  attr :id, :string, required: true
  attr :form, :any, required: true
  attr :target, :any, required: true
  attr :readonly, :boolean, default: false

  slot :inner_block, required: true

  def node(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "node group flex flex-wrap",
        "drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0",
        "drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0"
      ]}
      data-parent={@form[:parent_id].value}
      data-prev={@form[:prev_id].value}
    >
      <!--
      <button>
        <Core.icon name="hero-ellipsis-vertical" class="invisible w-5 h-5 group-hover:visible" />
      </button>
      <.outline_form for={@form} phx-change="noop" phx-submit="noop" phx-target={@target}>
        <Core.icon name="hero-check-circle" class="w-5 h-5" />
        <Core.icon name="hero-cog-6-tooth" class="w-5 h-5" />
        <Core.input field={@form[:checked]} type="checkbox" />

        <Core.input field={@form[:priority]} type="radio" value="red" />
        <Core.input field={@form[:priority]} type="radio" value="yellow" />
        <Core.input field={@form[:priority]} type="radio" value="green" />
      </.outline_form>
      -->
      <div class="ml-4 peer/children w-full order-last children group-data-[collapsed]:hidden"></div>
      <input
        class="invisible my-1 group-hover:visible selected peer/selected"
        type="checkbox"
        phx-click={JS.dispatch("toggle_select", detail: %{uuid: @form.data.uuid})}
      />
      <span class="hidden py-1 text-gray-500 cursor-pointer handle peer-empty/children:block">
        <.circle />
      </span>
      <button
        class="handle cursor-pointer py-1 text-gray-500 block peer-empty/children:hidden group-data-[collapsed]:-rotate-90 duration-200"
        phx-click={JS.dispatch("toggle_collapse", detail: %{uuid: @form.data.uuid})}
      >
        <.triangle />
      </button>
      <div
        id={[@id, "-content"]}
        class="peer-checked/selected:bg-yellow-100 inline-block pr-4 px-1 py-0.5 content focus:outline-none drag-ghost:opacity-0"
        contenteditable={!@readonly}
        phx-value-uuid={@form[:uuid].value}
        phx-focus="focus"
        phx-blur="blur"
        phx-target={@target}
      >
        {HTML.raw(@form[:content].value)}
      </div>
      <div class="text-xs text-white editing"></div>
    </div>
    """
  end

  def triangle(assigns) do
    ~H"""
    <svg viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5 rotate-90">
      <polygon points="7,5 7,15 15,10" />
    </svg>
    """
  end

  def circle(assigns) do
    ~H"""
    <svg viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
      <circle cx="10" cy="10" r="3.5"></circle>
    </svg>
    """
  end

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
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="flex items-center justify-between gap-6 mt-2">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def outline_input(%{field: %HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &Core.translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> outline_input()
  end

  def outline_input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class={@class}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        {@label}
      </label>
      <Core.error :for={msg <- @errors}>{msg}</Core.error>
    </div>
    """
  end

  def outline_input(%{type: "select"} = assigns) do
    ~H"""
    <div class={@class}>
      <Core.label for={@id}>{@label}</Core.label>
      <select
        id={@id}
        name={@name}
        class="block w-full mt-2 bg-white border border-gray-300 rounded-md shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {HTML.Form.options_for_select(@options, @value)}
      </select>
      <Core.error :for={msg <- @errors}>{msg}</Core.error>
    </div>
    """
  end

  def outline_input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class={@class}>
      <Core.label for={@id}>{@label}</Core.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem]",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      >{HTML.Form.normalize_value("textarea", @value)}</textarea>
      <Core.error :for={msg <- @errors}>{msg}</Core.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def outline_input(assigns) do
    ~H"""
    <div class={@class}>
      <Core.label for={@id}>{@label}</Core.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <Core.error :for={msg <- @errors}>{msg}</Core.error>
    </div>
    """
  end

  @doc """
  Renders the keyboard shortcuts.

  ## Examples

      <.keyboard_shortcuts />
  """
  def keyboard_shortcuts(assigns) do
    ~H"""
    <details>
      <summary>Shortcuts</summary>
      <dl class="divide-y divide-gray-100">
        <div class="grid grid-cols-4 gap-4 px-0 py-2">
          <dt class="text-sm leading-6 text-gray-600 font-small">Add note</dt>
          <dd class="col-span-1 mt-0 text-sm leading-6 text-gray-700">
            ↵
          </dd>
          <dt class="text-sm leading-6 text-gray-600 font-small">Collapse</dt>
          <dd class="col-span-1 mt-0 text-sm leading-6 text-gray-700"></dd>
        </div>
        <div class="grid grid-cols-4 gap-4 px-0 py-2">
          <dt class="text-sm leading-6 text-gray-600 font-small">Cursor up</dt>
          <dd class="col-span-1 mt-0 text-sm leading-6 text-gray-700">
            ↑
          </dd>
          <dt class="text-sm leading-6 text-gray-600 font-small">Expand</dt>
          <dd class="col-span-1 mt-0 text-sm leading-6 text-gray-700"></dd>
        </div>
        <div class="grid grid-cols-4 gap-4 px-0 py-2">
          <dt class="text-sm leading-6 text-gray-600 font-small">Cursor down</dt>
          <dd class="col-span-1 mt-0 text-sm leading-6 text-gray-700">
            ↓
          </dd>
          <dt class="text-sm leading-6 text-gray-600 font-small">Move node up</dt>
          <dd class="col-span-1 mt-0 text-sm leading-6 text-gray-700">⌥↑</dd>
        </div>

        <div class="grid grid-cols-4 gap-4 px-0 py-2">
          <dt class="text-sm leading-6 text-gray-600 font-small">Indent</dt>
          <dd class="col-span-1 mt-0 text-sm leading-6 text-gray-700">
            ⇥
          </dd>

          <dt class="text-sm leading-6 text-gray-600 font-small">Move node down</dt>
          <dd class="col-span-1 mt-0 text-sm leading-6 text-gray-700">⌥↓</dd>
        </div>
        <div class="grid grid-cols-4 gap-4 px-0 py-2">
          <dt class="text-sm leading-6 text-gray-600 font-small">Outdent</dt>
          <dd class="col-span-1 mt-0 text-sm leading-6 text-gray-700">
            ⇧⇥
          </dd>
        </div>
      </dl>
    </details>
    """
  end

  def event_logs(assigns) do
    ~H"""
    <details open>
      <summary>EVENT-LOG</summary>
      <ul id="event_logs" class="" phx-update="stream" phx-page-loading>
        <li :for={{id, event} <- @stream} id={id} class="my-4 border-2 rounded">
          <.event_entry event={event} />
        </li>
      </ul>
    </details>
    """
  end

  attr :event, :map, required: true

  defp event_entry(%{event: %NodeContentChangedEvent{}} = assigns) do
    ~H"""
    <div class="px-2 bg-gray-200">
      <Core.icon name="hero-pencil-square-solid" class="w-5 h-5" />
      {@event.event_id}
    </div>
    <div class="px-2 ml-8">
      <pre>{@event.node_id} - NodeContentChanged</pre>
      <p>content = {@event.content}</p>
    </div>
    """
  end

  defp event_entry(%{event: %NodeDeletedEvent{}} = assigns) do
    ~H"""
    <div class="px-2 bg-gray-200">
      <Core.icon name="hero-archive-box-x-mark-solid" class="w-5 h-5" />
      {@event.event_id}
    </div>
    <div class="px-2 ml-8">
      <pre>{@event.node.uuid} - NodeDeleted</pre>
      <p>next node = ?</p>
      <p>child nodes = ?</p>
    </div>
    """
  end

  defp event_entry(%{event: %NodeInsertedEvent{}} = assigns) do
    ~H"""
    <div class="px-2 bg-gray-200">
      <Core.icon name="hero-plus-solid" class="w-5 h-5" />
      {@event.event_id}
    </div>
    <div class="px-2 ml-8">
      <pre>{@event.node.uuid} - NodeInserted</pre>
      <p>parent_id = {@event.node.parent_id}</p>
      <p>prev_id = {@event.node.prev_id}</p>
      <p>next_id = {Outline.get_node_id(@event.next)}</p>
      <p>content = {@event.node.content}</p>
    </div>
    """
  end

  defp event_entry(%{event: %NodeMovedEvent{}} = assigns) do
    ~H"""
    <div class="px-2 bg-gray-200">
      <Core.icon name="hero-arrows-pointing-out-solid" class="w-5 h-5" />
      {@event.event_id}
    </div>
    <div class="px-2 ml-8">
      <pre>{@event.node.uuid} - NodeMoved</pre>
      <p>parent_id = {@event.node.parent_id}</p>
      <p>prev_id = {@event.node.prev_id}</p>
      <p>old_prev_id = {Outline.get_node_id(@event.old_prev)}</p>
      <p>old_next_id = {Outline.get_node_id(@event.old_next)}</p>
      <p>next_id = {Outline.get_node_id(@event.next)}</p>
    </div>
    """
  end

  def url_preview(%{type: "youtube"} = assigns) do
    ~H"""
    <div><Core.icon name="hero-play" class="w-5 h-5" /> YOUTUBE</div>
    <img src="/images/pic10.jpg" alt="" />
    <!--<iframe
      width="560"
      height="315"
      src={@url}
      title="YouTube video player"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      referrerpolicy="strict-origin-when-cross-origin"
      allowfullscreen
    >
    </iframe>-->
    """
  end

  def url_preview(%{type: "wikipedia"} = assigns) do
    ~H"""
    <div><Core.icon name="hero-book-open" class="w-5 h-5" /> WIKIPEDIA</div>
    """
  end

  def url_preview(%{type: "wikidata"} = assigns) do
    ~H"""
    <div>WIKIDATA</div>
    """
  end

  def url_preview(%{type: "website"} = assigns) do
    ~H"""
    <div><Core.icon name="hero-globe-alt" class="w-5 h-5" /> Website</div>

    <img src="/images/pic10.jpg" alt="" />
    """
  end
end
