defmodule RadiatorWeb.AshJsonApiRouter do
  @moduledoc false

  use AshJsonApi.Router,
    domains: [Radiator.Podcasts],
    open_api: "/open_api"
end
