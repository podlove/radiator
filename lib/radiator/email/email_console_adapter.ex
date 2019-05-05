defmodule Radiator.Email.Console do
  @moduledoc """
  Bamboo Adapter that logs emails to console.
  """
  @behaviour Bamboo.Adapter

  def deliver(email, _config) do
    from_name= email.from |> elem(0)
    from_email= email.from |> elem(1)
    IO.puts("Mail sent to #{from_name} <#{from_email}> with subject: '#{email.subject}'")
    IO.puts(email.text_body)
  end

  def handle_config(config), do: config

  def supports_attachments?, do: true
end