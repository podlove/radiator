defmodule Radiator.Accounts.RaindropClient do
  @moduledoc """
    Client for Raindrop API
  """
  require Logger

  alias Radiator.Accounts.Raindrop

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

  @doc """
  Check if the user has access to Raindrop API
  """
  def access_enabled?(user_id) do
    not_enabled =
      user_id
      |> Raindrop.get_raindrop_tokens()
      |> is_nil()

    !not_enabled
  end

  @doc """
  Get all collections for a user
  """
  def get_collections(user_id) do
    service =
      user_id
      |> Raindrop.get_raindrop_tokens()
      |> refresh_token_if()

    if is_nil(service) do
      {:error, :unauthorized}
    else
      [
        method: :get,
        url: "https://api.raindrop.io/rest/v1/collections",
        headers: [
          {"Authorization", "Bearer #{service.data.access_token}"}
        ]
      ]
      |> Req.request()
      |> parse_collection_response()
    end
  end

  @doc """
  Returns a string list of URLs in a collection
  """
  def list_urls_in_collection(user_id, collection_id) do
    service =
      user_id
      |> Raindrop.get_raindrop_tokens()
      |> refresh_token_if()

    if is_nil(service) do
      {:error, :unauthorized}
    else
      {:ok, %Req.Response{} = response} =
        [
          method: :get,
          url: "https://api.raindrop.io/rest/v1/raindrops/#{collection_id}",
          headers: [
            {"Authorization", "Bearer #{service.data.access_token}"}
          ]
        ]
        |> Req.request()

      response.body
      |> Map.get("items")
      |> Enum.map(fn item ->
        Map.get(item, "link")
      end)
    end
  end

  @doc """
    first time fetching access token and storing it as webservice entry
  """
  def init_and_store_access_token(user_id, code) do
    {:ok, response} =
      [
        method: :post,
        url: "https://raindrop.io/oauth/access_token",
        json: %{
          client_id: config()[:client_id],
          client_secret: config()[:client_secret],
          grant_type: "authorization_code",
          code: code,
          redirect_uri: redirect_uri()
        }
      ]
      |> Keyword.merge(config()[:options])
      |> Req.request()

    parse_access_token_response(response, user_id)
  end

  defp refresh_token_if(service) do
    if DateTime.before?(service.data.expires_at, DateTime.utc_now()) do
      {:ok, response} =
        [
          method: :post,
          url: "https://raindrop.io/oauth/access_token",
          headers: [
            {"Content-Type", "application/json"}
          ],
          json: %{
            client_id: config()[:client_id],
            client_secret: config()[:client_secret],
            grant_type: "refresh_token",
            refresh_token: service.data.refresh_token
          }
        ]
        |> Req.request()

      parse_access_token_response(response, service.user_id)
    else
      service
    end
  end

  defp parse_access_token_response(
         %Req.Response{
           body: %{
             "access_token" => access_token,
             "refresh_token" => refresh_token,
             "expires_in" => expires_in
           }
         },
         user_id
       ) do
    expires_at =
      DateTime.now!("Etc/UTC")
      |> DateTime.shift(second: expires_in)
      |> DateTime.truncate(:second)

    {:ok, service} =
      Raindrop.update_raindrop_tokens(
        user_id,
        access_token,
        refresh_token,
        expires_at
      )

    service
  end

  defp parse_access_token_response(response, _user_id) do
    Logger.error("Error fetching access token: #{inspect(response)}")
    {:error, :unauthorized}
  end

  defp parse_collection_response({:ok, %Req.Response{status: 401}}) do
    {:error, :unauthorized}
  end

  defp parse_collection_response({:ok, %Req.Response{body: body}}) do
    body
    |> Map.get("items")
    |> Enum.map(&Map.take(&1, ["_id", "title", "lastUpdate"]))
  end
end
