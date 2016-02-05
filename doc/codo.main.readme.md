# Design overview



## Instantiation
[Coming soon]

### Options
[Coming soon]

### Log configuration
[Coming soon]

## Scheduling of URLs
[Coming soon]

## Monitoring
[Coming soon]

## Scenario: Offline Crawling
[Coming soon]

## Scenario: Collecting data from parsed html
[Coming soon]

## Custom Extensions
[Coming soon]


```txt
 .-------------.
 |   INITIAL   |
 |-------------|
 | Unprocessed |
 |             |
 '-------------'   \
        |           \
        |            \
        |             v
        v             .--------------------.
 .-------------.      |  ERROR | CANCELED  |      .-----------.
 |  SPOOLED    |      |--------------------|      | COMPLETED |
 |-------------|  --->| - Error            |      |-----------|
 | Waiting for |      | - Duplicate        |      | Done!     |
 | free slot   |      | - Blacklisted etc. |      |           |
 '-------------'      '--------------------'      '-----------'
        |             ^         ^          ^            ^
        |            /          |           \           |
        |           /           |            \          |
        v          /                          \         |
 .-------------.         .-------------.          .-----------.
 |    READY    |         |  FETCHING   |          |  FETCHED  |
 |-------------|         |-------------|          |-----------|
 | Ready for   |-------->| Request     |--------->| Content   |
 | fetching    |         | streaming   |          | received  |
 '-------------'         '-------------'          '-----------'


```