defmodule Radiator.Outline.Event.NodeInsertedEvent do
  @moduledoc false

  defstruct [:uuid, :node, :user_id, :next_id, :episode_id]
end
