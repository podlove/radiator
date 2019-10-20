defmodule Radiator.InstanceConfig do
  @moduledoc """
  A module for accessing instance based config options.


  :base_admin_url - location to redirect to after successful email confirmation

  Set via config

  ```
  config :radiator, :instance_config,
    base_admin_url: "https://yourdomain.com/"
  ```

  """

  alias RadiatorWeb.Router.Helpers, as: Routes

  def base_admin_url do
    Application.get_env(:radiator, :instance_config)[:base_admin_url] ||
      Routes.admin_network_url(RadiatorWeb.Endpoint, :index)
  end

  def hostname do
    Application.get_env(:radiator, RadiatorWeb.Endpoint)[:url][:host]
  end
end
