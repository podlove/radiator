# Users and Permissions

Radiator offers a multi-tenancy architecture with global permissions to access/modify data on various levels in the hierarchy. A user can be the owner of a podcast or a whole podcast network/collection. A user can also be guest/invited to a podcast or episode with limited permissions.

## Authentication Model

Users are managed in the `Radiator.Auth.*` submodules. We have a minimal `Radiator.Auth.User` schema with `id, name, display_name, email, password_hash`. These users should be accessed, created, modified, checked using the `Radiator.Auth.Directory` context. The name can't be changed easily, `email` and `display_name` can be. Both `name` and `email` must be unique and present.  

Other (internal and external) parts of Radiator must use a relation to a `Radiator.Auth.User` to drive their authorization and permission model.

Schemas related to authentication should have a `auth_` table prefix, schemas related to permissions should have a `_permissions` table suffix.


## Authorization and Permissions

Permissions are stored closer to the entities they are connected to. E.g. there is a many to many relationship schema for podcasts, episodes and networks defining the access level for each user.

For example, to be able to edit an episode, a user must have one of either permissions:

* write episode with :id
* write podcast that contains episode :id
* write network/collection that contains the podcast with episode :id
* super admin privileges

### How do you model these permissions?

The “normalised” relational database approach would be an m:n-table.

* `EpisodePermissions` with `id, user_id, episode_id, permission` where `“permission”` is one of `“readonly, edit, manage”` with `“edit”` being for metadata editing and `“manage”` for more destructive actions like publishing, republishing, deleting. `“manage”` contains `“edit”` rights, so the account only needs the highest permission, not all.
* `PodcastPermissions` with `id, user_id, podcast_id, permission` where `“permission”` is one of `“readonly, edit, manage”` equivalent to above but also automatically applying to episodes in this podcast.
*  Similar permission-table for a connection between podcast network/collections (model does not exist yet)

Permission check goes from “top to bottom”, for example when checking for editing an episode:

1. is super admin?
1. has enough permissions on podcast collection/network?
1. has enough permissions on podcast?
1. has enough permissions on episode?
1. else… fail

(Permission check implementation for example in contexts with [https://hex.pm/packages/bodyguard])