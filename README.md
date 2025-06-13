# deckhand
Base docker image for Laravel CI

To build the current version for local testing:

    # On a Mac M-series chip:
    docker buildx build --platform linux/amd64 -t glhd/deckhand:dev .

    # On an Intel chip:
    docker build -t glhd/deckhand:dev .

To run the current build:

     docker run --rm -it glhd/deckhand:dev bash

To push and tag the current local dev build (change `8.4` to the current release tag):

    docker tag glhd/deckhand:dev glhd/deckhand:8.4 && docker push glhd/deckhand:8.4
