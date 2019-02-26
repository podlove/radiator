defmodule Radiator.Feed.Guards do
  defguard set?(v) when is_binary(v) and byte_size(v) > 0
end
