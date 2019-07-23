defmodule Radiator.Task do
  defstruct id: nil,
            total: 0,
            progress: 0,
            description: %{},
            start_time: DateTime.utc_now(),
            end_time: nil,
            state: :setup
end
