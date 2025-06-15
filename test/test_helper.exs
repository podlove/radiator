ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Radiator.Repo, :manual)

Application.put_env(:phoenix_test, :base_url, RadiatorWeb.Endpoint.url())
