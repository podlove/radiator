defmodule RadiatorWeb.LandingComponents do
  @moduledoc """
  Components for the public landing page.

  The page speaks to two audiences: listeners and podcast creators. Listener
  surfaces use the base colors, creator surfaces use the neutral "studio" color,
  so both halves stay recognisable across the whole page.
  """
  use RadiatorWeb, :html

  @doc """
  Concentric rings behind the hero that radiate outwards once on page load.
  """
  def radiating_rings(assigns) do
    ~H"""
    <%!-- The mask fades the rings out towards the section edges and dims them behind the text --%>
    <div
      aria-hidden="true"
      class="pointer-events-none absolute inset-0 -z-10 [mask-image:radial-gradient(closest-side,rgb(0_0_0/0.35),black_45%,black_65%,transparent)]"
    >
      <svg
        viewBox="0 0 800 800"
        fill="none"
        class="absolute top-1/2 left-1/2 size-[52rem] max-w-none -translate-x-1/2 -translate-y-1/2 text-primary"
      >
        <circle
          :for={{radius, opacity, delay} <- rings()}
          cx="400"
          cy="400"
          r={radius}
          stroke="currentColor"
          stroke-width="1.5"
          stroke-opacity={opacity}
          style={"animation-delay: #{delay}ms"}
          class="origin-center [transform-box:fill-box] motion-safe:animate-radiate"
        />
      </svg>
    </div>
    """
  end

  defp rings do
    [{110, 0.55, 0}, {185, 0.4, 120}, {260, 0.28, 240}, {335, 0.16, 360}, {395, 0.08, 480}]
  end

  @doc """
  One half of the split view: a pitch for either listeners or creators.
  """
  attr :id, :string, required: true
  attr :audience, :atom, values: [:listener, :creator], required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :title, :string, required: true

  slot :point, required: true do
    attr :icon, :string, required: true
    attr :soon, :boolean
  end

  slot :inner_block, doc: "a preview that shows what the audience gets"
  slot :actions, required: true

  def audience_card(assigns) do
    ~H"""
    <article
      id={@id}
      class={["flex flex-col gap-8 rounded-[1.75rem] p-6 sm:p-10", surface(@audience)]}
    >
      <header class="space-y-4">
        <p class="flex items-center gap-2 font-semibold text-primary">
          <.icon name={@icon} class="size-5" />
          {@label}
        </p>
        <h2 class="text-3xl font-bold tracking-tight text-balance sm:text-4xl">{@title}</h2>
      </header>

      <ul class="space-y-3 text-lg">
        <li :for={point <- @point} class="flex gap-3">
          <.icon name={point.icon} class="mt-1 size-5 shrink-0 text-primary" />
          <span>
            {render_slot(point)}
            <.soon_badge :if={point[:soon]} />
          </span>
        </li>
      </ul>

      <div :if={@inner_block != []} class="flex-1">
        {render_slot(@inner_block)}
      </div>

      <div class="flex flex-wrap items-center gap-x-6 gap-y-3">
        {render_slot(@actions)}
      </div>
    </article>
    """
  end

  defp surface(:listener), do: "bg-base-200 text-base-content"
  defp surface(:creator), do: "bg-neutral text-neutral-content"

  @doc """
  Marks a feature that is announced but not built yet.
  """
  def soon_badge(assigns) do
    ~H"""
    <span class="badge badge-sm badge-soft badge-primary ml-1 align-middle">Bald</span>
    """
  end

  @doc """
  The cover of a podcast, linking to its public page.
  """
  attr :id, :string, required: true
  attr :podcast, :any, required: true

  def podcast_cover(assigns) do
    ~H"""
    <.link
      id={@id}
      navigate={~p"/podcasts/#{@podcast}"}
      title={@podcast.title}
      class="group block overflow-hidden rounded-box bg-base-300 outline-offset-4 focus-visible:outline-2 focus-visible:outline-primary"
    >
      <img
        :if={@podcast.image_url}
        src={@podcast.image_url}
        alt={@podcast.title}
        loading="lazy"
        class="aspect-square size-full object-cover transition-transform duration-300 motion-safe:group-hover:scale-105"
      />
      <div :if={!@podcast.image_url} class="grid aspect-square place-items-center">
        <.icon name="hero-microphone" class="size-8 opacity-40" />
        <span class="sr-only">{@podcast.title}</span>
      </div>
    </.link>
    """
  end

  @doc """
  A static sketch of the collaborative outliner, as it could look during a recording.
  """
  def outliner_preview(assigns) do
    ~H"""
    <figure
      role="img"
      aria-label="Beispiel: Zwei Personen schreiben während einer Aufnahme im selben Outliner mit"
      class="rounded-box border border-neutral-content/15 bg-neutral-content/5 p-5 text-sm"
    >
      <div class="mb-4 flex items-center justify-between">
        <span class="font-semibold">Folge 42: Das neue Studio</span>
        <span class="flex -space-x-1">
          <span class="grid size-7 place-items-center rounded-full bg-primary text-[0.625rem] font-bold text-primary-content ring-2 ring-neutral">
            AK
          </span>
          <span class="grid size-7 place-items-center rounded-full bg-info text-[0.625rem] font-bold text-info-content ring-2 ring-neutral">
            JM
          </span>
        </span>
      </div>

      <ol class="space-y-2.5">
        <.outline_item time="00:00">Begrüßung</.outline_item>
        <.outline_item time="03:15">Neues Mikrofon im Studio</.outline_item>
        <.outline_item nested>
          <.icon name="hero-link-micro" class="size-3.5 opacity-60" /> Testbericht zum Mikrofon
        </.outline_item>
        <.outline_item nested>
          Hörerfrage von Kim: Welche Kopfhörer nutzt ihr?
          <.cursor name="Anna" color="bg-primary text-primary-content" />
        </.outline_item>
        <.outline_item time="21:40">
          Ausblick auf die nächste <.cursor name="Jo" color="bg-info text-info-content" />
        </.outline_item>
      </ol>
    </figure>
    """
  end

  attr :time, :string, default: nil
  attr :nested, :boolean, default: false
  slot :inner_block, required: true

  defp outline_item(assigns) do
    ~H"""
    <li class={["flex items-baseline gap-3", @nested && "pl-14 opacity-80"]}>
      <span :if={@time} class="w-11 shrink-0 tabular-nums opacity-50">{@time}</span>
      <span class="flex flex-wrap items-center gap-1">{render_slot(@inner_block)}</span>
    </li>
    """
  end

  attr :name, :string, required: true
  attr :color, :string, required: true

  defp cursor(assigns) do
    ~H"""
    <span class="inline-flex items-center">
      <span class={["h-4 w-0.5", @color]} />
      <span class={["rounded-sm px-1 text-[0.625rem] leading-4 font-semibold", @color]}>{@name}</span>
    </span>
    """
  end

  @doc """
  A single listener benefit.
  """
  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :soon, :boolean, default: false
  slot :inner_block, required: true

  def benefit(assigns) do
    ~H"""
    <div class="border-t border-base-300 pt-6">
      <dt class="flex items-center gap-3 text-lg font-semibold">
        <.icon name={@icon} class="size-6 shrink-0 text-primary" />
        <span>{@title} <.soon_badge :if={@soon} /></span>
      </dt>
      <dd class="mt-2 text-pretty opacity-75">{render_slot(@inner_block)}</dd>
    </div>
    """
  end

  @doc """
  One step of the creator workflow, from planning to talking with listeners.
  """
  attr :number, :integer, required: true
  attr :title, :string, required: true
  attr :soon, :boolean, default: false
  slot :inner_block, required: true

  def workflow_step(assigns) do
    ~H"""
    <li class="group">
      <div class="flex items-center gap-4">
        <span class="grid size-11 shrink-0 place-items-center rounded-full border-2 border-primary text-lg font-bold text-primary tabular-nums">
          {@number}
        </span>
        <span class="hidden h-px flex-1 bg-neutral-content/20 group-last:hidden md:block" />
      </div>
      <h3 class="mt-5 text-xl font-semibold">
        {@title} <.soon_badge :if={@soon} />
      </h3>
      <p class="mt-2 text-pretty opacity-75">{render_slot(@inner_block)}</p>
    </li>
    """
  end
end
