# Rules for working with AshJsonApi

## Understanding AshJsonApi

AshJsonApi is a package for integrating Ash Framework with the JSON:API specification. It provides tools for generating JSON:API compliant endpoints from your Ash resources. AshJsonApi allows you to expose your Ash resources through a standardized RESTful API, supporting all JSON:API features like filtering, sorting, pagination, includes, and relationships.

## Domain Configuration

AshJsonApi works by extending your Ash domains and resources with JSON:API capabilities. First, add the AshJsonApi extension to your domain.

### Setting Up Your Domain

```elixir
defmodule MyApp.Blog do
  use Ash.Domain,
    extensions: [
      AshJsonApi.Domain
    ]

  json_api do
    # Define JSON:API-specific settings for this domain
    authorize? true

    # You can define routes at the domain level
    routes do
      base_route "/posts", MyApp.Blog.Post do
        get :read
        index :read
        post :create
        patch :update
        delete :destroy
      end
    end
  end

  resources do
    resource MyApp.Blog.Post
    resource MyApp.Blog.Comment
  end
end
```

## Resource Configuration

Each resource that you want to expose via JSON:API needs to include the AshJsonApi.Resource extension.

### Setting Up Resources

```elixir
defmodule MyApp.Blog.Post do
  use Ash.Resource,
    domain: MyApp.Blog,
    extensions: [AshJsonApi.Resource]

  attributes do
    uuid_primary_key :id
    attribute :title, :string
    attribute :body, :string
    attribute :published, :boolean
  end

  relationships do
    belongs_to :author, MyApp.Accounts.User
    has_many :comments, MyApp.Blog.Comment
  end

  json_api do
    # The JSON:API type name (required)
    type "post"
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :list_published do
      filter expr(published == true)
    end

    update :publish do
      accept []
      change set_attribute(:published, true)
    end
  end
end
```

## Route Types

AshJsonApi supports various route types according to the JSON:API spec:

- `get` - Fetch a single resource by ID
- `index` - List resources, with support for filtering, sorting, and pagination
- `post` - Create a new resource
- `patch` - Update an existing resource
- `delete` - Destroy an existing resource
- `related` - Fetch related resources (e.g., `/posts/123/comments`)
- `relationship` - Fetch relationship data (e.g., `/posts/123/relationships/comments`)
- `post_to_relationship` - Add to a relationship
- `patch_relationship` - Replace a relationship
- `delete_from_relationship` - Remove from a relationship

## JSON:API Pagination, Filtering, and Sorting

AshJsonApi supports standard JSON:API query parameters:

- Filter: `?filter[attribute]=value`
- Sort: `?sort=attribute,-other_attribute` (descending with `-`)
- Pagination: `?page[number]=2&page[size]=10`
- Includes: `?include=author,comments.author`
