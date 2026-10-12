defmodule RadiatorWeb.AshJsonApiRouter do
  @moduledoc false

  use AshJsonApi.Router,
    domains: [],
    open_api: "/open_api"
end
