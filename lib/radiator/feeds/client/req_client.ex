defmodule Radiator.Feeds.Client.ReqClient do
  @moduledoc """
  Fetches feeds over Req.

  Four properties are set here deliberately:

    * A conditional request via `if-none-match` and `if-modified-since` — for
      an unchanged feed this saves the entire transfer and the parse.
    * `retry: false` — retries belong to Oban. Both mechanisms at once
      multiply the number of attempts.
    * A size limit, enforced while the body streams in, because there is a
      foreign URL at the other end.
    * A content-type check, because servers like to answer a broken feed with
      an HTML error page under status 200.

  The body is requested uncompressed. Req's `compressed` and `decompress_body`
  steps both step aside once `into:` streams the body, and reimplementing gzip
  with a bomb-proof inflate loop is not worth the bandwidth it would save on a
  feed that is mostly answered with 304 anyway.
  """

  alias Radiator.Feeds.Response

  @default_max_bytes 50 * 1024 * 1024
  @receive_timeout 30_000
  @user_agent "Radiator/1.0 (+https://github.com/podlove/radiator)"
  @xml_types ["xml", "rss", "atom"]

  @doc """
  Fetches a feed.

  Options: `:etag` and `:last_modified` for the conditional request,
  `:max_bytes` as an upper bound on the body.
  """
  def fetch(url, opts \\ []) do
    max_bytes = Keyword.get(opts, :max_bytes, @default_max_bytes)

    [
      url: url,
      headers: headers(opts),
      retry: false,
      receive_timeout: @receive_timeout,
      max_redirects: 5,
      into: collector(max_bytes)
    ]
    # The test config points `:plug` at `Req.Test`, so the client is exercised
    # end to end without a socket.
    |> Keyword.merge(Application.get_env(:radiator, __MODULE__, []))
    |> Req.new()
    |> Req.run()
    |> handle()
  end

  defp headers(opts) do
    [{"user-agent", @user_agent}]
    |> maybe_header("if-none-match", Keyword.get(opts, :etag))
    |> maybe_header("if-modified-since", Keyword.get(opts, :last_modified))
  end

  defp maybe_header(headers, _name, nil), do: headers
  defp maybe_header(headers, name, value), do: [{name, value} | headers]

  # Chunks are kept as iodata with a running byte count. Concatenating binaries
  # per chunk instead would copy the whole body on every one of them.
  defp collector(max_bytes) do
    fn {:data, data}, {req, resp} ->
      {chunks, size} = chunks(resp.body)
      size = size + byte_size(data)

      if size > max_bytes do
        {:halt, {req, %{resp | body: :too_large}}}
      else
        {:cont, {req, %{resp | body: {:chunks, [chunks, data], size}}}}
      end
    end
  end

  defp chunks({:chunks, iodata, size}), do: {iodata, size}
  defp chunks(_body), do: {[], 0}

  defp handle({_request, %Req.Response{body: :too_large}}), do: {:error, :feed_too_large}

  defp handle({_request, %Req.Response{} = response}) do
    dispatch(%{response | body: body(response.body)})
  end

  defp handle({_request, exception}), do: {:error, exception}

  defp body({:chunks, iodata, _size}), do: IO.iodata_to_binary(iodata)
  defp body(body) when is_binary(body), do: body
  defp body(_body), do: ""

  defp dispatch(%Req.Response{status: 304} = response), do: {:not_modified, to_response(response)}

  defp dispatch(%Req.Response{status: status} = response) when status in 200..299 do
    if xml?(response) do
      {:ok, to_response(response)}
    else
      {:error, {:unexpected_content_type, content_type(response)}}
    end
  end

  defp dispatch(%Req.Response{status: status} = response) when status in [429, 503] do
    {:error, {:http_status, status, retry_after(response)}}
  end

  defp dispatch(%Req.Response{status: status}), do: {:error, {:http_status, status}}

  defp xml?(response) do
    case content_type(response) do
      nil -> true
      type -> Enum.any?(@xml_types, &String.contains?(type, &1))
    end
  end

  defp content_type(response) do
    case raw_header(response, "content-type") do
      nil -> nil
      value -> value |> String.trim() |> String.downcase()
    end
  end

  defp to_response(response) do
    %Response{
      body: response.body,
      etag: raw_header(response, "etag"),
      last_modified: raw_header(response, "last-modified")
    }
  end

  defp raw_header(response, name), do: response |> Req.Response.get_header(name) |> List.first()

  # Reads `Retry-After` as a number of seconds, or `nil`. The header may also
  # hold an HTTP date. That form is rare enough that a date parser is not worth
  # it here; the caller falls back to exponential backoff.
  defp retry_after(response) do
    response
    |> Req.Response.get_header("retry-after")
    |> List.first()
    |> parse_retry_after()
  end

  defp parse_retry_after(nil), do: nil

  defp parse_retry_after(value) do
    case value |> String.trim() |> Integer.parse() do
      {seconds, ""} when seconds > 0 -> seconds
      _other -> nil
    end
  end
end
