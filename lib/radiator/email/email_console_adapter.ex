defmodule Radiator.Email.Console do
  @moduledoc """
  Bamboo Adapter that logs emails to console.
  """

  require Logger

  @behaviour Bamboo.Adapter

  def deliver(email, _config) do
    {from_name, from_email} = email.from
    {to_name, to_email} = hd(email.to)

    Logger.info(~s(Mail To: "#{to_name} <#{to_email}>"))
    Logger.info(~s(Mail From: "#{from_name} <#{from_email}>"))
    Logger.info(~s(Mail Subject: "#{email.subject}"))
    Logger.info(email.text_body)
  end

  def handle_config(config), do: config

  def supports_attachments?, do: true
end
