# Download Tracking

Download requests of audio files are tracked and recorded in the database. The schema module is `Radiator.Tracking.Download`.

## Architecture

There is a file tracking route that points to `RadiatorWeb.TrackingController`. This controller takes the download request, sends it asynchronously to `Radiator.Tracking.Server` and redirects the user to the requested file.

Tracking happens asynchronously in a separate process for two reasons:

1. If something in the tracking process fails, the user still gets to her download.
2. Downloads are served faster because the user does not need to wait for tracking processing to finish.

The actual tracking logic is in `Radiator.Tracking.track_download/1`:

- HEAD requests are detected and discarded (in `RadiatorWeb.TrackingController`)
- user agents are parsed into client, device, operating system
- bots are detected and discarded
- single-byte requests are detected and discarded
- a request id from IP and user agent is created for detection of unique requests

Each download keeps a reference to the audio file and its episode, podcast and network.

## Next Up

To generate meaningful and [IAB compliant](https://www.iab.com/guidelines/podcast-measurement-guidelines/) numbers, these entries need deduplication to get unique downloads based on `request_id` (user agent + IP address). The `Download.clean` field will be set to `false` for duplicate requests. 
