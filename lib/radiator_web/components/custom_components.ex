defmodule RadiatorWeb.CustomComponents do
  @moduledoc """
  Application-specific components.
  """
  use Phoenix.Component

  @doc """
  Drawer is a grid layout that can show/hide a sidebar on the left or right side of the page.

  ## Examples

      <.drawer>content</.drawer>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def drawer(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open">
      <input id="my-drawer-4" type="checkbox" class="drawer-toggle inline" />
      <div class="drawer-content">
        <nav class="navbar w-full bg-base-300">
          <label
            for="my-drawer-4"
            aria-label="open sidebar"
            class="btn btn-square btn-ghost drawer-button"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              stroke-linejoin="round"
              stroke-linecap="round"
              stroke-width="2"
              fill="none"
              stroke="currentColor"
              class="my-1.5 inline-block size-4"
            ><path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z">
            </path><path d="M9 4v16"></path><path d="M14 10l2 2l-2 2"></path></svg>
          </label>
          <div class="px-4">Navbar Title</div>
        </nav>
        <div class="p-4">
          {render_slot(@inner_block)}
        </div>
      </div>

      <div class="drawer-side is-drawer-close:overflow-visible">
        <label for="my-drawer-4" aria-label="close sidebar" class="drawer-overlay"></label>
        <div class="flex min-h-full flex-col items-start bg-base-200 is-drawer-close:w-14 is-drawer-open:w-64">
          <ul class="menu w-full grow">
            <li>
              <button
                class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
                data-tip="Episodes"
              >
                <RadiatorWeb.CoreComponents.icon
                  name="hero-list-bullet"
                  class="size-5"
                />
                <span class="is-drawer-close:hidden">Episodes</span>
              </button>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end
end
