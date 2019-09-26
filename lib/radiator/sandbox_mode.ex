defmodule Radiator.SandboxMode do
  @moduledoc """
  Global "Sandbox Mode".

  Set via config

      config :radiator, :sandbox_mode, enabled: false

  Or in released per ENV by setting `SANDBOX_MODE_ENABLED` to true.

  The following changes apply to a system in demo mode:

    - all feeds contain `<itunes:block>Yes</itunes:block>`
    - a robots.txt is generated disallowing all requests
  """
  def enabled? do
    Application.get_env(:radiator, :sandbox_mode)[:enabled] == true
  end
end
