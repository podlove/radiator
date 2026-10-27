defmodule RadiatorWeb.Components.DateTimePicker do
  @moduledoc """
  A date and time picker built on vanilla-calendar-pro (vendored in
  `assets/vendor/vanilla-calendar-pro`).

  The visible field opens a calendar with a 24-hour time picker. The chosen
  value goes into a hidden input as `YYYY-MM-DDTHH:MM`, the same local time
  a `datetime-local` input would submit, so the server side reads it the
  same way. When the server clears the field (after a save), the picker is
  cleared as well.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  attr :id, :string, required: true
  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true
  attr :placeholder, :string, default: nil
  attr :default_time, :string, default: "19:00", doc: "time preselected in the picker, `HH:MM`"
  attr :locale, :string, default: "de-DE"

  def date_time_picker(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook=".DateTimePicker"
      data-default-time={@default_time}
      data-locale={@locale}
      class="fieldset mb-2"
    >
      <label for={"#{@id}-display"} class="label mb-1">{@label}</label>
      <input type="hidden" name={@field.name} value={@field.value} data-picker-value />
      <div id={"#{@id}-display-wrapper"} phx-update="ignore" class="relative">
        <input
          id={"#{@id}-display"}
          type="text"
          readonly
          placeholder={@placeholder}
          autocomplete="off"
          class="input w-full cursor-pointer pr-10 sm:w-80"
          data-picker-display
        />
        <span class="hero-calendar-days pointer-events-none absolute right-3 top-1/2 size-5 -translate-y-1/2 text-base-content/50"></span>
      </div>
    </div>
    <script :type={ColocatedHook} name=".DateTimePicker">
      // The calendar is loaded only where a picker is shown: esbuild puts it
      // into its own chunk (see `--splitting` in config/config.exs).
      const loadCalendar = () => import("@/vendor/vanilla-calendar-pro/index.mjs");

      export default {
        mounted() {
          this.hidden = this.el.querySelector("[data-picker-value]");
          this.display = this.el.querySelector("[data-picker-display]");
          this.locale = this.el.dataset.locale;
          this.defaultTime = this.el.dataset.defaultTime;

          // Without a date the form would only come back with an error.
          this.form = this.el.closest("form");
          this.guard = (event) => {
            if (this.hidden.value === "") {
              event.preventDefault();
              event.stopPropagation();
              this.calendar?.show();
            }
          };
          this.form?.addEventListener("submit", this.guard);

          this.show();

          loadCalendar().then(({ Calendar, time }) => {
            if (this.isDestroyed) return;

            this.calendar = new Calendar(this.display, {
              inputMode: true,
              positionToInput: "auto",
              extensions: [time],
              selectionTimeMode: 24,
              selectedTime: this.defaultTime,
              timeStepMinute: 5,
              locale: this.locale,
              firstWeekday: 1,
              disableDatesPast: true,
              onChangeToInput: (self) => this.pick(self),
            });
            this.calendar.init();
          });
        },

        // The server clears the value once a proposal is saved.
        updated() {
          if (this.hidden.value === "" && this.display.value !== "") {
            this.calendar?.set(
              { selectedDates: [], selectedTime: this.defaultTime },
              { dates: true, time: true },
            );
          }
          this.show();
        },

        destroyed() {
          this.isDestroyed = true;
          this.form?.removeEventListener("submit", this.guard);
          this.calendar?.destroy();
        },

        pick(self) {
          const [date] = self.context.selectedDates;
          if (!date) return;

          const time = (self.context.selectedTime || this.defaultTime).slice(0, 5);
          this.hidden.value = `${date}T${time}`;
          this.show();
        },

        // Shows the hidden value as e.g. "Fr., 06.11.2026, 19:00".
        show() {
          const value = this.hidden.value;
          if (!value) {
            this.display.value = "";
            return;
          }

          const [date, time] = value.split("T");
          const [year, month, day] = date.split("-").map(Number);
          const [hour, minute] = time.split(":").map(Number);

          this.display.value = new Intl.DateTimeFormat(this.locale, {
            weekday: "short",
            day: "2-digit",
            month: "2-digit",
            year: "numeric",
            hour: "2-digit",
            minute: "2-digit",
          }).format(new Date(year, month - 1, day, hour, minute));
        },
      };
    </script>
    """
  end
end
