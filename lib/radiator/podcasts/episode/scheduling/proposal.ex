defmodule Radiator.Podcasts.Episode.Scheduling.Proposal do
  alias __MODULE__

  defstruct [:date_time, :votes]

  def new(date_time, votes) do
    %Proposal{date_time: date_time, votes: votes}
  end
end
