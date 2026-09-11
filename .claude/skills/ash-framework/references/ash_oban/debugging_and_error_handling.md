# Debugging and Error Handling

AshOban provides options for debugging and handling errors:

```elixir
trigger :process do
  action :process
  # Enable detailed debug logging for this trigger
  debug? true

  # Configure error handling
  log_errors? true
  log_final_error? true

  # Define an action to call after the last attempt has failed
  on_error :mark_failed
end
```

You can also enable global debug logging:

```elixir
config :ash_oban, :debug_all_triggers?, true
```

## Snoozing and Cancelling Jobs

From within any action run by a trigger or scheduled action, you can snooze or cancel the Oban job using special error types. These work from both the main action and the `on_error` action.

**Snooze** — re-schedule the job after a delay without consuming a retry attempt:

```elixir
# Via add_error (idiomatic for change functions):
Ash.Changeset.add_error(changeset, AshOban.Errors.SnoozeJob.exception(snooze_for: 60))

# Via raise:
raise AshOban.Errors.SnoozeJob, snooze_for: 60
```

**Cancel** — stop all retries and mark the job as cancelled:

```elixir
# Via add_error:
Ash.Changeset.add_error(changeset, AshOban.Errors.CancelJob.exception(reason: :permanently_invalid))

# Via raise:
raise AshOban.Errors.CancelJob, reason: :permanently_invalid
```
