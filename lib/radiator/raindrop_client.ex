defmodule Radiator.RaindropClient do
  @moduledoc """
    Client for Raindrop API
  """

  def config, do: Application.fetch_env!(:radiator, :raindrop)

  def redirect_uri(user_id) do
    config()[:redirect_url]
    |> URI.parse()
    |> URI.append_path("/#{user_id}")
    |> URI.to_string()
    |> URI.encode()
  end
end
