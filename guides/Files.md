# Files

## Audio

Audio files are either attached to an episode or a network. Episode-attached audios are your expected podcast audio files. However we want the ability to manage audios that are not attached to a specific podcast or episode. These are attached to the network and can be managed in that context.


       +---------+           +---------+
       | Network |           | Episode |
       +---------+           +---------+
           |                      |
           v                      v
    +----------------+   +----------------+
    | networks_audio |   | episodes_audio |
    +----------------+   +----------------+
           |                      |
           |      +-------+       |
           +----> | Audio | <-----+
                  +-------+












