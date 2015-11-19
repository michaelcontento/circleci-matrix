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

Then add your build matrix to a new file `.circleci-matrix.yml`, which is
the default name. If you wish to use another name you can pass the it as the
first argument on the command line (`$ circleci-matrix my-config.yml`).

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
    circleci-matrix version: 0.1.0
    circleci node total: 1
    circleci node index: 0

    -----------------------------------------------------------------
    Env: VERSION=5.0
    -----------------------------------------------------------------
    hi!
    Version is 5.0

    -----------------------------------------------------------------
    Env: VERSION=4.2
    -----------------------------------------------------------------
    hi!
    Version is 4.2

    -----------------------------------------------------------------
    Env: VERSION=4.1
    -----------------------------------------------------------------
    hi!
    Version is 4.1

    -----------------------------------------------------------------
    Env: VERSION=4.0
    -----------------------------------------------------------------
    hi!
    Version is 4.0

All commands have been executed with the right value in `$VERSION`.

## Parallelism

[CircleCI][]'s [parallelism][] is supported out of the box! Have a look at the
following example where I set `CIRCLE_NODE_TOTAL`and `CIRCLE_NODE_INDEX`
manually first to `2` and `0`, then to `2` and `1` to simulate two containers:

    $ CIRCLE_NODE_TOTAL=2 CIRCLE_NODE_INDEX=0 circle-matrix
    circleci-matrix version: 0.1.0
    circleci node total: 2
    circleci node index: 0

    -----------------------------------------------------------------
    Env: VERSION=5.0
    -----------------------------------------------------------------
    hi!
    Version is 5.0

    -----------------------------------------------------------------
    Env: VERSION=4.1
    -----------------------------------------------------------------
    hi!
    Version is 4.1

    $ CIRCLE_NODE_TOTAL=2 CIRCLE_NODE_INDEX=1 circle-matrix
    circleci-matrix version: 0.1.0
    circleci node total: 2
    circleci node index: 1

    -----------------------------------------------------------------
    Env: VERSION=4.2
    -----------------------------------------------------------------
    hi!
    Version is 4.2

    -----------------------------------------------------------------
    Env: VERSION=4.0
    -----------------------------------------------------------------
    hi!
    Version is 4.0

And here is the output when circleci runs our circle.yml file with 3 containers

Container 0 we see `VERSION=5.0` and `Version=4.0`:

    circleci-matrix version: 0.1.0
    circleci node total: 3
    circleci node index: 0

    -----------------------------------------------------------------
    Env: VERSION=5.0
    -----------------------------------------------------------------
    hi!
    Version is 5.0

    -----------------------------------------------------------------
    Env: VERSION=4.0
    -----------------------------------------------------------------
    hi!
    Version is 4.0

Container 1 we see `VERSION=4.2`:

    circleci-matrix version: 0.1.0
    circleci node total: 3
    circleci node index: 1

    -----------------------------------------------------------------
    Env: VERSION=4.2
    -----------------------------------------------------------------
    hi!
    Version is 4.2

Container 2 we see `VERSION=4.1`:

    circleci-matrix version: 0.1.0
    circleci node total: 3
    circleci node index: 2

    -----------------------------------------------------------------
    Env: VERSION=4.1
    -----------------------------------------------------------------
    hi!
    Version is 4.1

  [circleci-matrix]: https://github.com/michaelcontento/circleci-matrix
  [CircleCI]: https://circleci.com/
  [TravisCI]: https://travis-ci.org/
  [build matrix]: http://docs.travis-ci.com/user/customizing-the-build/#Build-Matrix
  [parallelism]: https://circleci.com/docs/setting-up-parallelism
