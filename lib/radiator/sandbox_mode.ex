defmodule Radiator.SandboxMode do
  @moduledoc """
  A global sandbox mode for the Radiator instance.

  The following changes apply to a system in sandbox mode:

    - all feeds contain `<itunes:block>Yes</itunes:block>`
    - a robots.txt is generated disallowing all requests

  Set via config

  ```
  config :radiator, :sandbox_mode, enabled: false
  ```

  Or in releases per ENV by setting `SANDBOX_MODE_ENABLED` to true.

  Status can be queried by clients:

  ```
  query {
    sandboxMode {
      enabled
    }
  }
  ```
  """
  def enabled? do
    Application.get_env(:radiator, :sandbox_mode)[:enabled] == true
  end
end
