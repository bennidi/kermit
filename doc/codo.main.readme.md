```txt

       Steps INITIAL
    --------------------
    - Filtering
    - Connect Queue     .-------------.       .------------.            Steps
    - User extensions   |   INITIAL   |       |  CANCELED  |          CANCELED
                        |-------------|       |------------|            ERROR
                        | Unprocessed |------>| Filtered   |          COMPLETED
                        |             |       | Duplicate  |     -------------------
                        '-------------'       |            |     - User extensions
       Steps SPOOLED          |               '------------'     - Cleanup
    --------------------      |
    - User extensions         v
                        .-------------.       .------------.           .-----------.
                        |   SPOOLED   |       |   ERROR    |           | COMPLETED |
                        |-------------|       |------------|           |-----------|
                        | Waiting for |------>| Processing |           | Done!     |
                        | free slot   |       | Error      |           |           |
                        '-------------'       '------------'           '-----------'
        Steps READY            |                     ^                       ^
    --------------------       |                     |                       |
    + User extensions          v                     |                       |
                        .-------------.       .-------------.          .-----------.
                        |    READY    |       |  FETCHING   |          |  FETCHED  |
                        |-------------|       |-------------|          |-----------|
                        | Ready for   |------>| Request     |--------->| Content   |
                        | fetching    |       | streaming   |          | received  |
                        '-------------'       '-------------'          '-----------'
                                              Steps FETCHING          Steps FETCHED
                                             ---------------------   -------------------
                                           + Request Streaming     + User extensions
                                           + User extensions

```