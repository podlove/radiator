defmodule Radiator.EventBased do

  # Event-Driven System
  #
  # Event Sourcing one of the most important patterns in event-driven systems
  #
  # event sourcing involves storing all changes to the application state as a log of change events
  # similiar to change data capture (cdc)
  #
  # Events represent state changes
  #
  # The event sourcing philosophy is careful to distinguish between events and com‐ mands [48].
  # When a request from a user first arrives, it is initially a command: at this point it may still fail,
  # for example because some integrity condition is violated. The application must first validate that
  #  it can execute the command. If the validation is successful and the command is accepted, it becomes an event,
  #  which is durable and immutable.
  #

  #
  # At the point when the event is generated, it becomes a fact.
  # A consumer of the event stream is not allowed to reject an event
  #
  # Eventstream:
  # append only stream of immutable facts
 # Commands are in the imperative:upgrade_customer_to_VIP.
 # Events are in past tense:customer_upgraded_to_VIP.
  Event
     payload
     timestamp
     type

  NodeInsertedEvent
  NodeUpdatedEvent
  NodeDeletedEvent
  NodeMovedEvent

  Events
    EventProcessor
    EventStore
    EventConsumer

  Commands
    CommandProcessor

  Aggregate
    execute function

  EventBus


    # not so much ..
   # .. more EventStore .. in our case table in DB
   # may be memory but easily lost
   # EventConsumer subscribes to EventStore
   # Phoenix.PubSub ?
   # GenStage polls the datbase? db trigger
   #
   # Events are designed by DDD, Stories, Use Cases .. and not model driven
   # they have a topic, a payload and a timestamp
   # also causeation id ... at least owner (events, commands)
   # correlation id ... prob not for us (workflow link to first event)
   # EventStream
   #

   # Commands are in the imperative:upgrade_customer_to_VIP.
   # Events are in past tense:customer_upgraded_to_VIP.

   # Commands execute synchronously and typically indicate completion, although they may also include a result
   # Events are both a fact and a notification. They represent something that happened in the real world but include no expectation of any future action.
   #
   # Events which are malformed or contain invalid data. In the same way that SQL rejects primary key violations,
   # or nulls where they shouldn’t be, or strings where integers should be — you need to validate inputs.
   # That means the event must be valid when it’s raised (within the eventual consistency constraints you build into
   # whatever UI/API is accepting requests and generating events — that subject could be a whole separate post…).
   #

end
