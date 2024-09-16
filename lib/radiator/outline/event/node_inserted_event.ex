defmodule Radiator.Outline.Event.NodeInsertedEvent do
  @moduledoc false

  defstruct [:event_id, :node, :user_id, :next, :episode_id, :content]
end
