defmodule Radiator.Cldr do
  use Cldr,
    locales: ["de", "en"],
    default_locale: "de",
    providers: [Cldr.Number]
end
