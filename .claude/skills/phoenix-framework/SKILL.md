---
name: phoenix-framework
description: "Use this skill working with Phoenix Framework. Consult this when working with the web layer, controllers, views, liveviews etc."
metadata:
  managed-by: usage-rules
---

<!-- usage-rules-skill-start -->
## Additional References

- [ecto](references/ecto.md)
- [elixir](references/elixir.md)
- [html](references/html.md)
- [liveview](references/liveview.md)
- [phoenix](references/phoenix.md)

## Searching Documentation

```sh
mix usage_rules.search_docs "search term" -p phoenix -p phoenix_ecto -p phoenix_html -p phoenix_live_dashboard -p phoenix_live_reload -p phoenix_live_view
```

## Available Mix Tasks

- `mix compile.phoenix`
- `mix phx` - Prints Phoenix help information
- `mix phx.digest` - Digests and compresses static files
- `mix phx.digest.clean` - Removes old versions of static assets.
- `mix phx.gen` - Lists all available Phoenix generators
- `mix phx.gen.auth` - Generates authentication logic for a resource
- `mix phx.gen.auth.hashing_library`
- `mix phx.gen.auth.injector`
- `mix phx.gen.auth.migration`
- `mix phx.gen.cert` - Generates a self-signed certificate for HTTPS testing
- `mix phx.gen.channel` - Generates a Phoenix channel
- `mix phx.gen.context` - Generates a context with functions around an Ecto schema
- `mix phx.gen.embedded` - Generates an embedded Ecto schema file
- `mix phx.gen.html` - Generates context and controller for an HTML resource
- `mix phx.gen.json` - Generates context and controller for a JSON resource
- `mix phx.gen.live` - Generates LiveView, templates, and context for a resource
- `mix phx.gen.notifier` - Generates a notifier that delivers emails by default
- `mix phx.gen.presence` - Generates a Presence tracker
- `mix phx.gen.release` - Generates release files and optional Dockerfile for release-based deployments
- `mix phx.gen.schema` - Generates an Ecto schema and migration file
- `mix phx.gen.secret` - Generates a secret
- `mix phx.gen.socket` - Generates a Phoenix socket handler
- `mix phx.routes` - Prints all routes
- `mix phx.server` - Starts applications and their servers
- `mix compile.phoenix_live_view`
- `mix phoenix_live_view.upgrade`
<!-- usage-rules-skill-end -->
