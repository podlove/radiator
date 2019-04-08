defmodule Radiator.Mailer do
  @otp_app Mix.Project.config()[:app]
  use Bamboo.Mailer, otp_app: @otp_app
end
