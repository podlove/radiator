defmodule RadiatorWeb.Public.RobotsTxtController do
  use RadiatorWeb, :controller

  alias Radiator.SandboxMode

  def show(conn, _) do
    text(conn, content(sandbox_mode: SandboxMode.enabled?()))
  end

  defp content(sandbox_mode: true) do
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
