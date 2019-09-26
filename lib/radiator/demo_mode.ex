defmodule Radiator.DemoMode do
  @moduledoc """
  Global "Demo Mode".

  Set via config

      config :radiator, :demo_mode, enabled: false

  Or in released per ENV by setting `DEMO_MODE_ENABLED` to true.

  The following changes apply to a system in demo mode:

    - all feeds contain `<itunes:block>Yes</itunes:block>`
    - a robots.txt is generated disallowing all requests
  """
  def enabled? do
    Application.get_env(:radiator, :demo_mode)[:enabled] == true
  end
end
