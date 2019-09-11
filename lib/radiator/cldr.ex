defmodule Radiator.Cldr do
  use Cldr,
    locales: ["de", "en"],
    efault_locale: "de",
    providers: [Cldr.Number]
end
