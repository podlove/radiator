# Mishka Chelekom CSS Configuration
#
# This file allows you to customize the CSS variables used by Mishka components.
# Uncomment and modify only the variables you want to override.
# Variable names use underscores instead of dashes (e.g., primary_light instead of --primary-light)

import Config

config :mishka_chelekom,
  # List of components to exclude from generation when using mix mishka.ui.gen.components
  # Example: ["alert", "badge", "button"]
  exclude_components: [],

  # Component attribute filters - limit which values are generated (reduces code size)
  # If empty or not specified, all values will be included

  # List of colors to include in component generation
  # Example: ["base", "primary", "danger", "success"]
  component_colors: [],

  # List of variants to include in component generation  
  # Example: ["default", "outline", "bordered"]
  component_variants: [],

  # List of sizes to include in component generation
  # Example: ["small", "medium", "large"]  
  component_sizes: [],

  # List of rounded options to include in component generation
  # Example: ["small", "medium", "full"]
  component_rounded: [],

  # List of padding options to include in component generation
  # Example: ["small", "medium", "large"]
  component_padding: [],

  # List of space options to include in component generation
  # Example: ["small", "medium", "large", "none"]
  component_space: [],

  # Override specific CSS variables (uncomment and modify as needed)
  css_overrides:
    %{
      # === Base Colors ===
      # base_border_light: "#e4e4e7",
      # base_border_dark: "#27272a",
      # base_text_light: "#09090b",
      # base_text_dark: "#fafafa",
      # base_bg_dark: "#18181b",
      # base_hover_light: "#f8f9fa",
      # base_hover_dark: "#242424",
      # base_disabled_bg_light: "#f1f3f5",
      # base_text_hover_light: "#1b1b1f",
      # base_text_hover_dark: "#ededed",
      # base_disabled_bg_dark: "#2e2e2e",
      # base_disabled_text_light: "#adb5bd",
      # base_disabled_text_dark: "#696969",
      # base_disabled_border_light: "#dee2e6",
      # base_disabled_border_dark: "#424242",
      # base_tab_bg_light: "#f4f4f5",

      # === Default Colors ===
      # default_dark_bg: "#282828",
      # default_light_gray: "#f4f4f4",
      # default_gray: "#b6b6b6",
      # ring_dark: "#050404",
      # default_device_dark: "#404040",
      # range_light_gray: "#e6e6e6",

      # === Natural Theme ===
      # natural_light: "#4b4b4b",
      # natural_dark: "#dddddd",
      # natural_hover_light: "#282828",
      # natural_hover_dark: "#e8e8e8",
      # natural_bordered_hover_light: "#E8E8E8",
      # natural_bordered_hover_dark: "#5E5E5E",
      # natural_bg_light: "#f3f3f3",
      # natural_bg_dark: "#4b4b4b",
      # natural_border_light: "#282828",
      # natural_border_dark: "#e8e8e8",
      # natural_bordered_text_light: "#282828",
      # natural_bordered_text_dark: "#e8e8e8",
      # natural_bordered_bg_light: "#f3f3f3",
      # natural_bordered_bg_dark: "#4b4b4b",
      # natural_disabled_light: "#dddddd",
      # natural_disabled_dark: "#727272",

      # === Primary Theme ===
      # primary_light: "#007f8c",
      # primary_dark: "#01b8ca",
      # primary_hover_light: "#016974",
      # primary_hover_dark: "#77d5e3",
      # primary_bordered_text_light: "#016974",
      # primary_bordered_text_dark: "#77d5e3",
      # primary_bordered_bg_light: "#e2f8fb",
      # primary_bordered_bg_dark: "#002d33",
      # primary_indicator_light: "#1a535a",
      # primary_indicator_dark: "#b0e7ef",
      # primary_border_light: "#000000",
      # primary_border_dark: "#b0e7ef",
      # primary_gradient_indicator_dark: "#cdeef3",

      # === Secondary Theme ===
      # secondary_light: "#266ef1",
      # secondary_dark: "#6daafb",
      # secondary_hover_light: "#175bcc",
      # secondary_hover_dark: "#a9c9ff",
      # secondary_bordered_text_light: "#175bcc",
      # secondary_bordered_text_dark: "#a9c9ff",
      # secondary_bordered_bg_light: "#eff4fe",
      # secondary_bordered_bg_dark: "#002661",
      # secondary_indicator_light: "#1948a3",
      # secondary_indicator_dark: "#cddeff",
      # secondary_border_light: "#1948a3",
      # secondary_border_dark: "#cddeff",
      # secondary_gradient_indicator_dark: "#dee9fe",

      # === Success Theme ===
      # success_light: "#0e8345",
      # success_dark: "#06c167",
      # success_hover_light: "#166c3b",
      # success_hover_dark: "#7fd99a",
      # success_bordered_text_light: "#166c3b",
      # success_bordered_text_dark: "#7fd99a",
      # success_bordered_bg_light: "#eaf6ed",
      # success_bordered_bg_dark: "#002f14",
      # success_indicator_light: "#047857",
      # success_indicator_alt_light: "#0d572d",
      # success_indicator_dark: "#b1eac2",
      # success_border_light: "#0d572d",
      # success_border_dark: "#b1eac2",
      # success_gradient_indicator_dark: "#d3efda",

      # === Warning Theme ===
      # warning_light: "#ca8d01",
      # warning_dark: "#fdc034",
      # warning_hover_light: "#976a01",
      # warning_hover_dark: "#fdd067",
      # warning_bordered_text_light: "#976a01",
      # warning_bordered_text_dark: "#fdd067",
      # warning_bordered_bg_light: "#fff7e6",
      # warning_bordered_bg_dark: "#322300",
      # warning_indicator_light: "#ff8b08",
      # warning_indicator_alt_light: "#654600",
      # warning_indicator_dark: "#fedf99",
      # warning_border_light: "#654600",
      # warning_border_dark: "#fedf99",
      # warning_gradient_indicator_dark: "#feefcc",

      # === Danger Theme ===
      # danger_light: "#de1135",
      # danger_dark: "#fc7f79",
      # danger_hover_light: "#bb032a",
      # danger_hover_dark: "#ffb2ab",
      # danger_bordered_text_light: "#bb032a",
      # danger_bordered_text_dark: "#ffb2ab",
      # danger_bordered_bg_light: "#fff0ee",
      # danger_bordered_bg_dark: "#520810",
      # danger_indicator_light: "#e73b3b",
      # danger_indicator_alt_light: "#950f22",
      # danger_indicator_dark: "#ffd2cd",
      # danger_border_light: "#950f22",
      # danger_border_dark: "#ffd2cd",
      # danger_gradient_indicator_dark: "#ffe1de",

      # === Info Theme ===
      # info_light: "#0b84ba",
      # info_dark: "#3eb7ed",
      # info_hover_light: "#08638c",
      # info_hover_dark: "#6ec9f2",
      # info_bordered_text_light: "#0b84ba",
      # info_bordered_text_dark: "#6ec9f2",
      # info_bordered_bg_light: "#e7f6fd",
      # info_bordered_bg_dark: "#03212f",
      # info_indicator_light: "#004fc4",
      # info_indicator_alt_light: "#06425d",
      # info_indicator_dark: "#9fdbf6",
      # info_border_light: "#06425d",
      # info_border_dark: "#9fdbf6",
      # info_gradient_indicator_dark: "#cfedfb",

      # === Misc Theme ===
      # misc_light: "#8750c5",
      # misc_dark: "#ba83f9",
      # misc_hover_light: "#653c94",
      # misc_hover_dark: "#cba2fa",
      # misc_bordered_text_light: "#653c94",
      # misc_bordered_text_dark: "#cba2fa",
      # misc_bordered_bg_light: "#f6f0fe",
      # misc_bordered_bg_dark: "#221431",
      # misc_indicator_light: "#52059c",
      # misc_indicator_alt_light: "#442863",
      # misc_indicator_dark: "#ddc1fc",
      # misc_border_light: "#442863",
      # misc_border_dark: "#ddc1fc",
      # misc_gradient_indicator_dark: "#eee0fd",

      # === Dawn Theme ===
      # dawn_light: "#a86438",
      # dawn_dark: "#db976b",
      # dawn_hover_light: "#7e4b2a",
      # dawn_hover_dark: "#e4b190",
      # dawn_bordered_text_light: "#7e4b2a",
      # dawn_bordered_text_dark: "#e4b190",
      # dawn_bordered_bg_light: "#fbf2ed",
      # dawn_bordered_bg_dark: "#2a190e",
      # dawn_indicator_light: "#4d4137",
      # dawn_indicator_alt_light: "#54321c",
      # dawn_indicator_dark: "#edcbb5",
      # dawn_border_light: "#54321c",
      # dawn_border_dark: "#edcbb5",
      # dawn_gradient_indicator_dark: "#f6e5da",

      # === Silver Theme ===
      # silver_light: "#868686",
      # silver_dark: "#a6a6a6",
      # silver_hover_light: "#727272",
      # silver_hover_dark: "#bbbbbb",
      # silver_hover_bordered_light: "#E8E8E8",
      # silver_hover_bordered_dark: "#5E5E5E",
      # silver_bordered_text_light: "#727272",
      # silver_bordered_text_dark: "#bbbbbb",
      # silver_bordered_bg_light: "#f3f3f3",
      # silver_bordered_bg_dark: "#4b4b4b",
      # silver_indicator_light: "#707483",
      # silver_indicator_alt_light: "#5e5e5e",
      # silver_indicator_dark: "#dddddd",
      # silver_border_light: "#5e5e5e",
      # silver_border_dark: "#dddddd",

      # === Borders & States ===
      # bordered_white_border: "#dddddd",
      # bordered_dark_bg: "#282828",
      # bordered_dark_border: "#727272",
      # disabled_bg_light: "#f3f3f3",
      # disabled_bg_dark: "#4b4b4b",
      # disabled_text_light: "#bbbbbb",
      # disabled_text_dark: "#868686",

      # === Shadows ===
      # shadow_natural: "rgba(134, 134, 134, 0.5)",
      # shadow_primary: "rgba(0, 149, 164, 0.5)",
      # shadow_secondary: "rgba(6, 139, 238, 0.5)",
      # shadow_success: "rgba(0, 154, 81, 0.5)",
      # shadow_warning: "rgba(252, 176, 1, 0.5)",
      # shadow_danger: "rgba(248, 52, 70, 0.5)",
      # shadow_info: "rgba(14, 165, 233, 0.5)",
      # shadow_misc: "rgba(169, 100, 247, 0.5)",
      # shadow_dawn: "rgba(210, 125, 70, 0.5)",
      # shadow_silver: "rgba(134, 134, 134, 0.5)",

      # === Gradients ===
      # gradient_natural_from_light: "#282828",
      # gradient_natural_to_light: "#727272",
      # gradient_natural_from_dark: "#a6a6a6",
      # gradient_primary_from_light: "#016974",
      # gradient_primary_to_light: "#01b8ca",
      # gradient_primary_from_dark: "#01b8ca",
      # gradient_primary_to_dark: "#b0e7ef",
      # gradient_secondary_from_light: "#175bcc",
      # gradient_secondary_to_light: "#6daafb",
      # gradient_secondary_from_dark: "#6daafb",
      # gradient_secondary_to_dark: "#cddeff",
      # gradient_success_from_light: "#166c3b",
      # gradient_success_to_light: "#06c167",
      # gradient_success_from_dark: "#06c167",
      # gradient_success_to_dark: "#b1eac2",
      # gradient_warning_from_light: "#976a01",
      # gradient_warning_to_light: "#fdc034",
      # gradient_warning_from_dark: "#fdc034",
      # gradient_warning_to_dark: "#fedf99",
      # gradient_danger_from_light: "#bb032a",
      # gradient_danger_to_light: "#fc7f79",
      # gradient_danger_from_dark: "#fc7f79",
      # gradient_danger_to_dark: "#ffd2cd",
      # gradient_info_from_light: "#08638c",
      # gradient_info_to_light: "#3eb7ed",
      # gradient_info_from_dark: "#3eb7ed",
      # gradient_info_to_dark: "#9fdbf6",
      # gradient_misc_from_light: "#653c94",
      # gradient_misc_to_light: "#ba83f9",
      # gradient_misc_from_dark: "#ba83f9",
      # gradient_misc_to_dark: "#ddc1fc",
      # gradient_dawn_from_light: "#7e4b2a",
      # gradient_dawn_to_light: "#db976b",
      # gradient_dawn_from_dark: "#db976b",
      # gradient_dawn_to_dark: "#edcbb5",
      # gradient_silver_from_light: "#5e5e5e",
      # gradient_silver_to_light: "#a6a6a6",
      # gradient_silver_from_dark: "#868686",
      # gradient_silver_to_dark: "#bbbbbb",

      # === Form Elements ===
      # base_form_border_light: "#8b8b8d",
      # base_form_border_dark: "#818182",
      # base_form_focus_dark: "#696969",
      # form_white_text: "#3e3e3e",
      # form_white_focus: "#dadada",

      # === Checkbox Colors ===
      # checkbox_unchecked_dark: "#333333",
      # checkbox_white_checked: "#ede8e8",
      # checkbox_dark_checked: "#616060",
      # checkbox_primary_checked: "#0095a4",
      # checkbox_secondary_checked: "#068bee",
      # checkbox_success_checked: "#009a51",
      # checkbox_warning_checked: "#fcb001",
      # checkbox_danger_checked: "#f83446",
      # checkbox_info_checked: "#0ea5e9",
      # checkbox_misc_checked: "#a964f7",
      # checkbox_dawn_checked: "#d27d46",
      # checkbox_silver_checked: "#a6a6a6",

      # === Stepper Colors ===
      # stepper_loading_icon_fill: "#2563eb",
      # stepper_current_step_text_light: "#2563eb",
      # stepper_current_step_text_dark: "#1971c2",
      # stepper_current_step_border_light: "#2563eb",
      # stepper_current_step_border_dark: "#1971c2",
      # stepper_completed_step_bg_light: "#14b8a6",
      # stepper_completed_step_bg_dark: "#099268",
      # stepper_completed_step_border_light: "#14b8a6",
      # stepper_completed_step_border_dark: "#099268",
      # stepper_canceled_step_bg_light: "#fa5252",
      # stepper_canceled_step_bg_dark: "#e03131",
      # stepper_canceled_step_border_light: "#fa5252",
      # stepper_canceled_step_border_dark: "#e03131",
      # stepper_separator_completed_border_light: "#14b8a6",
      # stepper_separator_completed_border_dark: "#099268"
    },

  # Strategy for handling CSS
  # :merge - Merge overrides with defaults (recommended)
  # :replace - Completely replace with custom CSS file
  css_merge_strategy: :merge,

  # Path to custom CSS file (only used when css_merge_strategy is :replace)
  # custom_css_path: "priv/static/css/custom_mishka.css"
  custom_css_path: nil
