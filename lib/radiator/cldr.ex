defmodule Radiator.Cldr do
  @moduledoc """
  CLDR (Common Locale Data Repository) configuration for Capo.

  Provides localization support for English and German locales with
  number formatting, calendar, and date/time functionality.
  """

  use Cldr,
    otp_app: :radiator,
    locales: ["en", "de"],
    default_locale: "en",
    providers: [
      Cldr.Language,
      AshTrans
    ]
end
