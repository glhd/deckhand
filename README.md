# deckhand
Base docker image for Laravel CI

To build current version for local testing:

    docker build -t glhd/deckhand:dev .

To run the current build:

     docker run --rm -it glhd/deckhand:dev bash

To push and tag the current local dev build (change `7.4` to the current release tag):

    docker tag glhd/deckhand:dev glhd/deckhand:7.4 && docker push glhd/deckhand:7.4
