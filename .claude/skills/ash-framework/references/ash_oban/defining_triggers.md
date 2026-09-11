# Defining Triggers

Triggers are the primary way to define background jobs in AshOban. They can be configured to run when certain conditions are met on your resources. They work
by running a scheduler job on the given cron job.

## Basic Trigger

```elixir
oban do
  triggers do
    trigger :process do
      action :process
      scheduler_cron "*/5 * * * *"
      where expr(processed != true)
      worker_read_action :read
      worker_module_name MyApp.Workers.Process
      scheduler_module_name MyApp.Schedulers.Process
    end
  end
end
```

## Trigger Configuration Options

- `action` - The action to be triggered (required)
- `where` - The filter expression to determine if something should be triggered
- `worker_read_action` - The read action to use when fetching individual records
- `read_action` - The read action to use when querying records (must support keyset pagination)
- `worker_module_name` - The module name for the generated worker (important for job stability)
- `scheduler_module_name` - The module name for the generated scheduler
- `max_attempts` - How many times to attempt the job (default: 1)
- `queue` - The queue to place the worker job in (defaults to trigger name)
- `trigger_once?` - Ensures that jobs that complete quickly aren't rescheduled (default: false)
