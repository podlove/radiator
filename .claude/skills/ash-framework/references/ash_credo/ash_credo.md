# Rules for working with AshCredo

## Understanding AshCredo

AshCredo is a Credo plugin providing static analysis checks for projects
built with the Ash Framework. Checks cover Ash resources, domains, and the
code that calls into them. Some checks analyse the unexpanded source AST;
others introspect compiled modules and see the fully resolved DSL state,
including anything Spark transformers and extensions contribute.

## Setup

Register the plugin in `.credo.exs`:

    %{
      configs: [
        %{
          name: "default",
          plugins: [{AshCredo, []}]
        }
      ]
    }

Projects using Igniter can run `mix igniter.install ash_credo` instead,
which adds the dependency and registers the plugin.

Registering the plugin matters: it enables the default checks and sets up
the run-scoped cache. Checks added directly to `checks:` without the
plugin still work, but they run uncached and without any defaults.

## Enabling checks

The plugin enables only a small, low-noise set of checks by default; most
checks are opt-in. Don't guess check names. The authoritative list is the
checks table in the README (<https://ash-credo.hexdocs.pm/readme.html#checks>,
or `deps/ash_credo/README.md` inside a consuming project), which carries
each check's category, default state, and configurable parameters, plus a
ready-to-paste "enable all checks" block. Enable opt-in checks by adding
them to `checks: %{extra: [...]}` in `.credo.exs`.

## Compile before running

Many checks introspect compiled BEAM modules rather than the source AST.
Run `mix compile` before `mix credo`, for example via an alias:

    lint: ["compile", "credo --strict"]

On an uncompiled project those checks emit "could not load" diagnostics
instead of real results. The affected checks are listed in the README
under "Checks that require a compiled project".
