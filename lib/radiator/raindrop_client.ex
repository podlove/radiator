defmodule Radiator.RaindropClient do
  @moduledoc """
    Client for Raindrop API
  """

  def config, do: Application.fetch_env!(:radiator, :raindrop)
end
