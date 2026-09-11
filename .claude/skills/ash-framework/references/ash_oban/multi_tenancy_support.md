# Multi-tenancy Support

AshOban supports multi-tenancy in your Ash application:

```elixir
oban do
  # Global tenant configuration
  list_tenants [1, 2, 3]  # or a function that returns tenants

  triggers do
    trigger :process do
      # Override tenants for a specific trigger
      list_tenants fn -> [2] end
      action :process
    end
  end
end
```
