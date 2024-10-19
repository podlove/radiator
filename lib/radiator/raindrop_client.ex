defmodule Radiator.RaindropClient do
  @moduledoc """
    Client for Raindrop API
  """
  @config Application.compile_env(:radiator, [:service, :raindrop])

  def config, do: @config
end
