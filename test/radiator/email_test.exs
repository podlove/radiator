defmodule Radiator.EmailTest do
  use Radiator.DataCase, async: true

  import Swoosh.TestAssertions

  alias Radiator.Accounts.User.Senders.SendMagicLinkEmail

  test "send email" do
    user = "user@example.com"
    token = "token12345"

    SendMagicLinkEmail.send(user, token, [])

    assert_email_sent(fn email ->
      assert email.subject == "Dein Login-Link"
      assert email.from == {"Radiator: No Reply", "noreply@radiator.metaebene.net"}
      assert email.to == [{"", "user@example.com"}]

      assert email.html_body =~ "Hier kannst du dich anmelden"
      assert email.html_body =~ "http://localhost:4002/auth/user/magic_link?token=#{token}"
    end)
  end
end
