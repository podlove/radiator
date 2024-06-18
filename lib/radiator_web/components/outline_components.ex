defmodule RadiatorWeb.OutlineComponents do
  @moduledoc """
  Provides components for an outline.
  """
  use Phoenix.Component

  import RadiatorWeb.CoreComponents, only: [icon: 1]

  attr :type, :string, values: ~w(clean insert change_content move delete)
  attr :class, :string, default: nil

  def event_type_icon(%{type: "clean"} = assigns) do
    ~H"""
    <.icon name="hero-check-solid" class={@class} />
    """
  end

  def event_type_icon(%{type: "insert"} = assigns) do
    ~H"""
    <.icon name="hero-plus-solid" class={@class} />
    """
  end

  def event_type_icon(%{type: "change_content"} = assigns) do
    ~H"""
    <.icon name="hero-pencil-solid" class={@class} />
    """
  end

  def event_type_icon(%{type: "move"} = assigns) do
    ~H"""
    <.icon name="hero-chevron-up-down-solid" class={@class} />
    """
  end

  def event_type_icon(%{type: "delete"} = assigns) do
    ~H"""
    <.icon name="hero-trash-solid" class={@class} />
    """
  end
end
