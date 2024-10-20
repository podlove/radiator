defmodule Radiator.RaindropClient do
  @moduledoc """
    Client for Raindrop API
  """

  def config, do: Application.fetch_env!(:radiator, :raindrop)

  def redirect_uri_encoded(user_id) do
    user_id
    |> redirect_uri()
    |> URI.encode()
  end

  def redirect_uri(user_id) do
    config()[:redirect_url]
    |> URI.parse()
    |> URI.append_query("user_id=#{user_id}")
    |> URI.to_string()
  end

  def redirect_uri do
    config()[:redirect_url]
    |> URI.parse()
    |> URI.to_string()
  end
end
