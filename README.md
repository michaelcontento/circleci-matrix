[circleci-matrix][]
===================

Small utility to mirror [TravisCI][]'s [build matrix][] on [CircleCI][].

## Installation

Simply download `src/circleci-matrix.sh` and make it executable:

    curl -fsSL https://raw.githubusercontent.com/michaelcontento/circleci-matrix/master/src/circleci-matrix.sh \
        -o /usr/local/bin/circleci-matrix \
        && chmod +x /usr/local/bin/circleci-matrix


**NOTE**: The `ubuntu` user used by [CircleCI][] machines has no permissions to
write to `/use/local/bin`! A good alternative is `~/.local/bin`!

As a alternative you could paste this into your `circle.yml`:

    dependencies:
        pre:
        # Install circleci-matrix
        - mkdir -p ~/.local/bin
        - curl -fsSL https://raw.githubusercontent.com/michaelcontento/circleci-matrix/master/src/circleci-matrix.sh -o ~/.local/bin/circleci-matrix
        - chmod +x ~/.local/bin/circleci-matrix

## Usage

First you need to define your build matrix in a new file called
`.circleci-matrix.yml` like this:

    env:
        - VERSION=5.0
        - VERSION=4.2
        - VERSION=4.1
        - VERSION=4.0

    command:
        - echo 'hi!'
        - echo "Version is $VERSION"

Now you're ready to execute it with:

    $ circleci-matrix
    INFO: circleci-matrix version: 0.1.0
    INFO: circleci node total: 1
    INFO: circleci node index: 0

    INFO: Running env: VERSION=5.0
    INFO: Running command: echo 'hi!'
    hi!
    INFO: Running command: echo "Version is $VERSION"
    Version is 5.0

    INFO: Running env: VERSION=4.2
    INFO: Running command: echo 'hi!'
    hi!
    INFO: Running command: echo "Version is $VERSION"
    Version is 4.2

    INFO: Running env: VERSION=4.1
    INFO: Running command: echo 'hi!'
    hi!
    INFO: Running command: echo "Version is $VERSION"
    Version is 4.1

    INFO: Running env: VERSION=4.0
    INFO: Running command: echo 'hi!'
    hi!
    INFO: Running command: echo "Version is $VERSION"
    Version is 4.0

    INFO: Done

All commands have been executed with the right value in `$VERSION`.

## Parallelism

[CircleCI][]'s [parallelism][] is supported out of the box! Have a look at the following
example where I set the `CIRCLE_NODE_TOTAL` manually:

    $ CIRCLE_NODE_TOTAL=4 circleci-matrix
    INFO: circleci-matrix version: 0.1.0
    INFO: circleci node total: 4
    INFO: circleci node index: 0

    INFO: Running env: VERSION=5.0
    INFO: Running command: echo 'hi!'
    hi!
    INFO: Running command: echo "Version is $VERSION"
    Version is 5.0

    INFO: Skipping env: VERSION=4.2

    INFO: Skipping env: VERSION=4.1

    INFO: Skipping env: VERSION=4.0

    INFO: Done

  [circleci-matrix]: https://github.com/michaelcontento/circleci-matrix
  [CircleCI]: https://circleci.com/
  [TravisCI]: https://travis-ci.org/
  [build matrix]: http://docs.travis-ci.com/user/customizing-the-build/#Build-Matrix
  [parallelism]: https://circleci.com/docs/setting-up-parallelism
