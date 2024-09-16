defmodule Radiator.Outline.Event.NodeDeletedEvent do
  @moduledoc false
  defstruct [:event_id, :node, :user_id, :children, :next, :episode_id]
end
