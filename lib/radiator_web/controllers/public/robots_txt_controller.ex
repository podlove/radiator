defmodule RadiatorWeb.Public.RobotsTxtController do
  use RadiatorWeb, :controller

  def show(conn, _) do
    text(conn, content(demo_mode: Radiator.DemoMode.enabled?()))
  end

  defp content(demo_mode: true) do
    """
    User-agent: *
    Disallow: /
    """
  end

  defp content(_) do
    """
    User-agent: *
    Disallow:
    """
  end
end
