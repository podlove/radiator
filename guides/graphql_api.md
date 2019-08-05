# GraphQL API

Generated using 
```sh
get-graphql-schema http://localhost:4000/api/graphql
```

```
schema {
  query: RootQueryType
  mutation: RootMutationType
}

"""An audio object"""
type Audio {
  audioFiles: [AudioFile]
  audioPublication: AudioPublication
  chapters(order: SortOrder = ASC): [Chapter]
  contributions: [Contribution]
  duration: Int
  durationString: String
  episodes: [Episode]
  id: ID!
  image: String
  title: String
}

"""Audio File"""
type AudioFile {
  byteLength: Int
  file: String
  id: Int
  mimeType: String
  title: String
}

type AudioPublication {
  audio: Audio

  """drafted, scheduled, published, depublished"""
  id: Int
  publishState: String
  publishedAt: DateTime
  title: String
}

"""A chapter in an episode"""
type Chapter {
  image: String
  link: String
  start: Int
  startString: String
  title: String
}

"""A radiator instance user that is allowed to work on this subject"""
type Collaborator {
  permission: Permission
  subject: PermissionSubject
  user: User
}

"""A record of a Person having contributed"""
type Contribution {
  contributionRole: ContributionRole
  id: ID!
  person: Person
  position: Float
}

"""A Contribution Role"""
type ContributionRole {
  id: ID!
  isPublic: Boolean
  title: String
}

"""
The `DateTime` scalar type represents a date and time in the UTC
timezone. The DateTime appears in a JSON response as an ISO8601 formatted
string, including UTC timezone ("Z"). The parsed date and time string will
be converted to UTC and any UTC offset other than 0 will be rejected.
"""
scalar DateTime

"""An episode in a podcast"""
type Episode {
  audio: Audio
  guid: String
  id: ID!
  image: String
  isPublished: Boolean
  number: Int
  podcast: Podcast

  """drafted, scheduled, published, depublished"""
  publishState: String
  publishedAt: DateTime
  shortId: String
  slug: String
  subtitle: String
  summary: String
  summaryHtml: String
  summarySource: String
  title: String
}

enum EpisodeOrder {
  PUBLISHED_AT
  TITLE
}

"""Info about podcast feeds found at an url"""
type FeedInfo {
  feeds: [PodcastFeed]
  image: String
  link: String
  subtitle: String
  suggestedShortId: String
  title: String
}

"""A network"""
type Network {
  audioPublications: [AudioPublication]
  collaborators: [Collaborator]
  id: ID!
  image: String
  people: [Person]
  podcasts: [Podcast]
  slug: String
  title: String
}

"""A type of access permission."""
enum Permission {
  """editor"""
  EDIT

  """manager"""
  MANAGE

  """owner"""
  OWN

  """viewer"""
  READONLY
}

"""A subject for permissions / user roles. E.g. a Network, Podcast, etc."""
union PermissionSubject = Network | Podcast

"""A radiator instance person"""
type Person {
  displayName: String
  email: String
  id: ID!
  image: String
  link: String
  name: String
  nick: String
}

"""A podcast"""
type Podcast {
  author: String
  contributions: [Contribution]
  episodes(itemsPerPage: Int = 10, order: SortOrder = DESC, orderBy: EpisodeOrder = PUBLISHED_AT, page: Int = 1, published: Published = ANY): [Episode]
  episodesCount: Int
  id: ID!
  image: String
  isPublished: Boolean
  language: String
  lastBuiltAt: DateTime
  ownerEmail: String
  ownerName: String
  publishedAt: DateTime
  shortId: String
  slug: String
  subtitle: String
  summary: String
  title: String
}

"""A Podcast feed"""
type PodcastFeed {
  author: String
  description: String
  enclosureType: String
  episodeCount: Int!
  episodes: [PodcastFeedEpisode]
  feedUrl: String
  image: String
  link: String
  subtitle: String
  summary: String
  title: String
  waitingForPages: Boolean!
}

"""A podcast feed episode"""
type PodcastFeedEpisode {
  contentEncoded: String
  description: String
  duration: String
  enclosureType: String
  enclosureUrl: String
  episode: String
  guid: String
  image: String
  link: String
  season: String
  subtitle: String
  summary: String
  title: String
}

"""A radiator instance user accessible to others"""
type PublicUser {
  displayName: String
  image: String
  username: String
}

enum Published {
  ANY
  FALSE
  TRUE
}

"""A published episode in a podcast"""
type PublishedEpisode {
  audio: Audio
  guid: String
  id: ID!
  image: String
  number: Int
  podcast: PublishedPodcast
  publishedAt: DateTime
  shortId: String
  slug: String
  subtitle: String
  summary: String
  summaryHtml: String
  summarySource: String
  title: String
}

"""A published network"""
type PublishedNetwork {
  id: ID!
  image: String
  podcasts: [PublishedPodcast]
  slug: String
  title: String
}

"""A published podcast"""
type PublishedPodcast {
  author: String
  episodes(itemsPerPage: Int = 10, order: SortOrder = DESC, orderBy: EpisodeOrder = PUBLISHED_AT, page: Int = 1): [PublishedEpisode]
  id: ID!
  image: String
  language: String
  lastBuiltAt: DateTime
  ownerEmail: String
  ownerName: String
  publishedAt: DateTime
  publishedEpisodesCount: Int
  shortId: String
  slug: String
  subtitle: String
  summary: String
  title: String
}

type RootMutationType {
  """Request an authenticated session"""
  authenticatedSession(password: String!, usernameOrEmail: String!): Session

  """Delete an episode"""
  deleteEpisode(id: ID!): Episode

  """Depublish episode"""
  depublishEpisode(id: ID!): Episode

  """Depublish podcast"""
  depublishPodcast(id: ID!): Podcast

  """Prolong an authenticated session"""
  prolongSession: Session

  """Publish podcast"""
  publishPodcast(id: ID!): Podcast

  """Schedule episode"""
  scheduleEpisode(datetime: DateTime!, id: ID!): Episode

  """Request resend of verification email (need auth)"""
  userResendVerificationEmail: Boolean

  """Sign up a user"""
  userSignup(email: String!, password: String!, username: String!): Session
}

type RootQueryType {
  """Get one audio"""
  audio(id: ID!): Audio

  """Get all possible contribution roles"""
  contributionRoles: [ContributionRole]

  """Get one episode"""
  episode(id: ID!): Episode

  """Get podcast feed info for an url"""
  feedInfo(url: String!): FeedInfo

  """Get one network"""
  network(id: ID!): Network

  """Get all networks"""
  networks: [Network]

  """Get one podcast"""
  podcast(id: ID!): Podcast

  """Get the content of a feed url"""
  podcastFeed(url: String!): PodcastFeed

  """Get all podcasts"""
  podcasts: [Podcast]

  """Get one published episode"""
  publishedEpisode(id: ID!): PublishedEpisode

  """Get one published network"""
  publishedNetwork(id: ID!): PublishedNetwork

  """Get all published networks"""
  publishedNetworks: [PublishedNetwork]

  """Get one published podcast"""
  publishedPodcast(id: ID!): PublishedPodcast

  """Get all published podcasts"""
  publishedPodcasts: [PublishedPodcast]

  """Get current user"""
  user: User

  """Find users of this instance"""
  users(query: String!): [PublicUser]
}

"""A user API session"""
type Session {
  expiresAt: DateTime
  token: String
  username: String
}

enum SortOrder {
  ASC
  DESC
}

"""A radiator instance user accessible to admins and yourself"""
type User {
  displayName: String
  email: String
  image: String
  username: String
}

```