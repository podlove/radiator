
require Ash.Query

licenses = [
  # --- CC 4.0 (current) ---
  %{
    name: "Creative Commons Attribution 4.0 International",
    short_name: "CC BY 4.0",
    version: "4.0",
    url: "https://creativecommons.org/licenses/by/4.0/",
    class: :cc,
    kind: :license,
    status: :current
  },
  %{
    name: "Creative Commons Attribution-ShareAlike 4.0 International",
    short_name: "CC BY-SA 4.0",
    version: "4.0",
    url: "https://creativecommons.org/licenses/by-sa/4.0/",
    class: :cc,
    kind: :license,
    status: :current
  },
  %{
    name: "Creative Commons Attribution-NoDerivatives 4.0 International",
    short_name: "CC BY-ND 4.0",
    version: "4.0",
    url: "https://creativecommons.org/licenses/by-nd/4.0/",
    class: :cc,
    kind: :license,
    status: :current
  },
  %{
    name: "Creative Commons Attribution-NonCommercial 4.0 International",
    short_name: "CC BY-NC 4.0",
    version: "4.0",
    url: "https://creativecommons.org/licenses/by-nc/4.0/",
    class: :cc,
    kind: :license,
    status: :current
  },
  %{
    name: "Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International",
    short_name: "CC BY-NC-SA 4.0",
    version: "4.0",
    url: "https://creativecommons.org/licenses/by-nc-sa/4.0/",
    class: :cc,
    kind: :license,
    status: :current
  },
  %{
    name: "Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International",
    short_name: "CC BY-NC-ND 4.0",
    version: "4.0",
    url: "https://creativecommons.org/licenses/by-nc-nd/4.0/",
    class: :cc,
    kind: :license,
    status: :current
  },

  # --- CC 3.0 (legacy) ---
  %{
    name: "Creative Commons Attribution 3.0 Unported",
    short_name: "CC BY 3.0",
    version: "3.0",
    url: "https://creativecommons.org/licenses/by/3.0/",
    class: :cc,
    kind: :license,
    status: :legacy
  },
  %{
    name: "Creative Commons Attribution-ShareAlike 3.0 Unported",
    short_name: "CC BY-SA 3.0",
    version: "3.0",
    url: "https://creativecommons.org/licenses/by-sa/3.0/",
    class: :cc,
    kind: :license,
    status: :legacy
  },
  %{
    name: "Creative Commons Attribution-NoDerivatives 3.0 Unported",
    short_name: "CC BY-ND 3.0",
    version: "3.0",
    url: "https://creativecommons.org/licenses/by-nd/3.0/",
    class: :cc,
    kind: :license,
    status: :legacy
  },
  %{
    name: "Creative Commons Attribution-NonCommercial 3.0 Unported",
    short_name: "CC BY-NC 3.0",
    version: "3.0",
    url: "https://creativecommons.org/licenses/by-nc/3.0/",
    class: :cc,
    kind: :license,
    status: :legacy
  },
  %{
    name: "Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported",
    short_name: "CC BY-NC-SA 3.0",
    version: "3.0",
    url: "https://creativecommons.org/licenses/by-nc-sa/3.0/",
    class: :cc,
    kind: :license,
    status: :legacy
  },
  %{
    name: "Creative Commons Attribution-NonCommercial-NoDerivatives 3.0 Unported",
    short_name: "CC BY-NC-ND 3.0",
    version: "3.0",
    url: "https://creativecommons.org/licenses/by-nc-nd/3.0/",
    class: :cc,
    kind: :license,
    status: :legacy
  },

  # --- CC 2.5 (retired, but common) ---
  %{
    name: "Creative Commons Attribution 2.5 Generic",
    short_name: "CC BY 2.5",
    version: "2.5",
    url: "https://creativecommons.org/licenses/by/2.5/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-ShareAlike 2.5 Generic",
    short_name: "CC BY-SA 2.5",
    version: "2.5",
    url: "https://creativecommons.org/licenses/by-sa/2.5/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NoDerivatives 2.5 Generic",
    short_name: "CC BY-ND 2.5",
    version: "2.5",
    url: "https://creativecommons.org/licenses/by-nd/2.5/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NonCommercial 2.5 Generic",
    short_name: "CC BY-NC 2.5",
    version: "2.5",
    url: "https://creativecommons.org/licenses/by-nc/2.5/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NonCommercial-ShareAlike 2.5 Generic",
    short_name: "CC BY-NC-SA 2.5",
    version: "2.5",
    url: "https://creativecommons.org/licenses/by-nc-sa/2.5/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NonCommercial-NoDerivatives 2.5 Generic",
    short_name: "CC BY-NC-ND 2.5",
    version: "2.5",
    url: "https://creativecommons.org/licenses/by-nc-nd/2.5/",
    class: :cc,
    kind: :license,
    status: :retired
  },

  # --- CC 2.0 (retired, still found) ---
  %{
    name: "Creative Commons Attribution 2.0 Generic",
    short_name: "CC BY 2.0",
    version: "2.0",
    url: "https://creativecommons.org/licenses/by/2.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-ShareAlike 2.0 Generic",
    short_name: "CC BY-SA 2.0",
    version: "2.0",
    url: "https://creativecommons.org/licenses/by-sa/2.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NoDerivatives 2.0 Generic",
    short_name: "CC BY-ND 2.0",
    version: "2.0",
    url: "https://creativecommons.org/licenses/by-nd/2.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NonCommercial 2.0 Generic",
    short_name: "CC BY-NC 2.0",
    version: "2.0",
    url: "https://creativecommons.org/licenses/by-nc/2.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic",
    short_name: "CC BY-NC-SA 2.0",
    version: "2.0",
    url: "https://creativecommons.org/licenses/by-nc-sa/2.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NonCommercial-NoDerivatives 2.0 Generic",
    short_name: "CC BY-NC-ND 2.0",
    version: "2.0",
    url: "https://creativecommons.org/licenses/by-nc-nd/2.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },

  # --- CC 1.0 (retired, rare) ---
  %{
    name: "Creative Commons Attribution 1.0 Generic",
    short_name: "CC BY 1.0",
    version: "1.0",
    url: "https://creativecommons.org/licenses/by/1.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-ShareAlike 1.0 Generic",
    short_name: "CC BY-SA 1.0",
    version: "1.0",
    url: "https://creativecommons.org/licenses/by-sa/1.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NoDerivatives 1.0 Generic",
    short_name: "CC BY-ND 1.0",
    version: "1.0",
    url: "https://creativecommons.org/licenses/by-nd/1.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NonCommercial 1.0 Generic",
    short_name: "CC BY-NC 1.0",
    version: "1.0",
    url: "https://creativecommons.org/licenses/by-nc/1.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NonCommercial-ShareAlike 1.0 Generic",
    short_name: "CC BY-NC-SA 1.0",
    version: "1.0",
    url: "https://creativecommons.org/licenses/by-nc-sa/1.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },
  %{
    name: "Creative Commons Attribution-NonCommercial-NoDerivatives 1.0 Generic",
    short_name: "CC BY-NC-ND 1.0",
    version: "1.0",
    url: "https://creativecommons.org/licenses/by-nc-nd/1.0/",
    class: :cc,
    kind: :license,
    status: :retired
  },

  # --- Public domain tools ---
  %{
    name: "Creative Commons CC0 1.0 Universal (CC0 1.0) Public Domain Dedication",
    short_name: "CC0 1.0",
    version: "1.0",
    url: "https://creativecommons.org/publicdomain/zero/1.0/",
    class: :pd,
    kind: :tool,
    status: :current
  },
  %{
    name: "Public Domain Mark 1.0",
    short_name: "PDM 1.0",
    version: "1.0",
    url: "https://creativecommons.org/publicdomain/mark/1.0/",
    class: :pd,
    kind: :tool,
    status: :current
  }
]

names = Enum.map(licenses, & &1.name)

# Delete the existing records for licenses by name

Radiator.Podcasts.License
  |> Ash.Query.filter(name in ^names)
  |> Ash.bulk_destroy!(:destroy, %{}, strategy: :atomic, authorize?: false)


# And re-insert fresh copies of them
licenses
|> Enum.map(&Map.take(&1, [:name, :short_name, :url]))
|> Ash.bulk_create!(Radiator.Podcasts.License, :create, return_errors?: true, authorize?: false)
