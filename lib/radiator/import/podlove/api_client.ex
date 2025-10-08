defmodule Radiator.Import.Podlove.ApiClient do
  @moduledoc """
  HTTP client for the Podlove Publisher API v2.

  This module provides functions to interact with WordPress sites running
  the Podlove Publisher plugin via its REST API.

  ## Authentication

  The Podlove API supports Basic Authentication using WordPress credentials:

      Radiator.Import.Podlove.ApiClient.fetch_podcast(
        "https://example.com",
        auth: {"username", "password"}
      )

  For WordPress Application Passwords, use the application password as the password.

  ## API Documentation

  See: https://docs.podlove.org/podlove-publisher/api/
  """

  require Logger

  @default_timeout 30_000

  @doc """
  Fetches podcast metadata from the Podlove API.

  ## Options

    * `:auth` - `{username, password}` tuple for Basic Authentication
    * `:timeout` - Request timeout in milliseconds (default: #{@default_timeout})

  ## Examples

      iex> ApiClient.fetch_podcast("https://example.com")
      {:ok, %{"title" => "My Podcast", ...}}

      iex> ApiClient.fetch_podcast("https://example.com", auth: {"user", "pass"})
      {:ok, %{"title" => "My Podcast", ...}}

  ## Returns

    * `{:ok, podcast_map}` - Podcast metadata as a map
    * `{:error, reason}` - Error message
  """
  def fetch_podcast(base_url, opts \\ []) do
    url = build_api_url(base_url, "/podlove/v2/podcast")

    case make_request(url, opts) do
      {:ok, body} -> {:ok, body}
      {:error, reason} -> {:error, "Failed to fetch podcast: #{reason}"}
    end
  end

  @doc """
  Fetches a list of all episodes from the Podlove API.

  Returns a list of episode summaries. For full episode details,
  use `fetch_episode/3` for each episode.

  ## Options

    * `:auth` - `{username, password}` tuple for Basic Authentication
    * `:timeout` - Request timeout in milliseconds (default: #{@default_timeout})

  ## Examples

      iex> ApiClient.fetch_episodes("https://example.com")
      {:ok, [%{"id" => 1, "title" => "Episode 1"}, ...]}

  ## Returns

    * `{:ok, [episode_map]}` - List of episode summaries
    * `{:error, reason}` - Error message
  """
  def fetch_episodes(base_url, opts \\ []) do
    url = build_api_url(base_url, "/podlove/v2/episodes")

    case make_request(url, opts) do
      {:ok, body} ->
        episodes =
          case body do
            %{"results" => results} when is_list(results) -> results
            results when is_list(results) -> results
            _ -> []
          end

        {:ok, episodes}

      {:error, reason} ->
        {:error, "Failed to fetch episodes: #{reason}"}
    end
  end

  @doc """
  Fetches detailed information for a specific episode.

  ## Options

    * `:auth` - `{username, password}` tuple for Basic Authentication
    * `:timeout` - Request timeout in milliseconds (default: #{@default_timeout})

  ## Examples

      iex> ApiClient.fetch_episode("https://example.com", 42)
      {:ok, %{"id" => 42, "title" => "Episode 42", ...}}

  ## Returns

    * `{:ok, episode_map}` - Episode details as a map
    * `{:error, reason}` - Error message
  """
  def fetch_episode(base_url, episode_id, opts \\ []) do
    url = build_api_url(base_url, "/podlove/v2/episodes/#{episode_id}")

    case make_request(url, opts) do
      {:ok, body} -> {:ok, body}
      {:error, reason} -> {:error, "Failed to fetch episode #{episode_id}: #{reason}"}
    end
  end

  @doc """
  Fetches chapters for a specific episode.

  ## Options

    * `:auth` - `{username, password}` tuple for Basic Authentication
    * `:timeout` - Request timeout in milliseconds (default: #{@default_timeout})

  ## Examples

      iex> ApiClient.fetch_chapters("https://example.com", 42)
      {:ok, [%{"start" => "00:00:00", "title" => "Intro"}, ...]}

  ## Returns

    * `{:ok, [chapter_map]}` - List of chapters
    * `{:error, reason}` - Error message
  """
  def fetch_chapters(base_url, episode_id, opts \\ []) do
    url = build_api_url(base_url, "/podlove/v2/chapters/#{episode_id}")

    case make_request(url, opts) do
      {:ok, body} ->
        chapters =
          case body do
            %{"chapters" => chapters} when is_list(chapters) -> chapters
            chapters when is_list(chapters) -> chapters
            _ -> []
          end

        {:ok, chapters}

      {:error, reason} ->
        # Chapters are optional, so we don't treat 404 as an error
        Logger.debug("No chapters found for episode #{episode_id}: #{reason}")
        {:ok, []}
    end
  end

  # Private Functions

  defp make_request(url, opts) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    auth = Keyword.get(opts, :auth)

    request_opts = [
      url: url,
      receive_timeout: timeout
    ]

    request_opts =
      if auth do
        add_basic_auth(request_opts, auth)
      else
        request_opts
      end

    case Req.get(request_opts) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: 401}} ->
        {:error, "Authentication required or invalid credentials"}

      {:ok, %{status: 404}} ->
        {:error, "Resource not found (HTTP 404)"}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, %{reason: reason}} ->
        {:error, "Network error: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp add_basic_auth(request_opts, {username, password}) do
    credentials = Base.encode64("#{username}:#{password}")
    auth_header = {"authorization", "Basic #{credentials}"}

    Keyword.update(request_opts, :headers, [auth_header], fn headers ->
      [auth_header | headers]
    end)
  end

  defp build_api_url(base_url, path) do
    base_url = String.trim_trailing(base_url, "/")
    "#{base_url}/wp-json#{path}"
  end
end
