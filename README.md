[circleci-matrix][]
===================

- **Linux:** [![Linux Build](https://travis-ci.org/michaelcontento/circleci-matrix.svg)](https://travis-ci.org/michaelcontento/circleci-matrix)
- **OSX:** [![OSX Build](https://circleci.com/gh/michaelcontento/circleci-matrix/tree/master.svg?style=shield&circle-token=e8011fe1b683964966f04ecf39c170f65bd3f6dc)](https://circleci.com/gh/michaelcontento/circleci-matrix/tree/master)

Small utility to mirror [TravisCI][]'s [build matrix][] on [CircleCI][].

# No longer maintained

My focus / time shifted and this tool is no longer maintained.

If you want to step in and become the new owner - just ping me :smile:

Thank you for your patience and using this module in the first place!

## Features

- Simple one file distribution
  - Really! `src/circleci-matrix.sh` contains everything you need.
- No special requirements on OSX or Linux
- Supports [parallelism][] out of the box
- Using different config files is as simple as `--config anotherConfig.yml`
- A rich set of tests ensures that everything will work as expected

## Installation

Simply download `src/circleci-matrix.sh` and make it executable:

    curl -fsSL https://git.io/v2Ifs \
        -o /usr/local/bin/circleci-matrix \
        && chmod +x /usr/local/bin/circleci-matrix


**NOTE**: The `ubuntu` user used by [CircleCI][] machines has no permissions to
write to `/use/local/bin`! A good alternative is `~/.local/bin`!

As a alternative you could paste this into your `circle.yml`:

    dependencies:
        pre:
        # Install circleci-matrix
        - mkdir -p ~/.local/bin
        - curl -fsSL https://git.io/v2Ifs -o ~/.local/bin/circleci-matrix
        - chmod +x ~/.local/bin/circleci-matrix

Or, if you like to have a cleaner `circle.yml`, use the installer:

    dependencies:
        pre:
        - curl -fsSL https://git.io/v2Ifn | bash

## Usage

Then add your build matrix to a new file `.circleci-matrix.yml`, which is
the default name. If you wish to use another name you can set it via the
command line option `--config/-c` (`$ circleci-matrix --config my-config.yml`).

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
    -----------------------------------------------------------------
    -- circleci-matrix version: 1.0.0
    -- circleci node total: 1
    -- circleci node index: 0
    -----------------------------------------------------------------

    -----------------------------------------------------------------
    -- Env: VERSION=5.0
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 5.0

    -----------------------------------------------------------------
    -- Env: VERSION=4.2
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 4.2

    -----------------------------------------------------------------
    -- Env: VERSION=4.1
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 4.1

    -----------------------------------------------------------------
    -- Env: VERSION=4.0
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 4.0

All commands have been executed with the right value in `$VERSION`.

## Parallelism

[CircleCI][]'s [parallelism][] is supported out of the box! Have a look at the
following example where I set `CIRCLE_NODE_TOTAL` and `CIRCLE_NODE_INDEX`
manually first to `2` and `0`, then to `2` and `1` to simulate two containers:

**Container 0:**

    $ CIRCLE_NODE_TOTAL=2 CIRCLE_NODE_INDEX=0 circle-matrix
    -----------------------------------------------------------------
    -- circleci-matrix version: 1.0.0
    -- circleci node total: 2
    -- circleci node index: 0
    -----------------------------------------------------------------

    -----------------------------------------------------------------
    -- Env: VERSION=5.0
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 5.0

    -----------------------------------------------------------------
    -- Env: VERSION=4.1
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 4.1

**Container 1:**

    $ CIRCLE_NODE_TOTAL=2 CIRCLE_NODE_INDEX=1 circle-matrix
    -----------------------------------------------------------------
    -- circleci-matrix version: 1.0.0
    -- circleci node total: 2
    -- circleci node index: 1
    -----------------------------------------------------------------

    -----------------------------------------------------------------
    -- Env: VERSION=4.2
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 4.2

    -----------------------------------------------------------------
    -- Env: VERSION=4.0
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 4.0

And here is the output when circleci runs our circle.yml file with 3 containers

**Container 0** we see `VERSION=5.0` and `Version=4.0`:

    -----------------------------------------------------------------
    -- circleci-matrix version: 1.0.0
    -- circleci node total: 3
    -- circleci node index: 0
    -----------------------------------------------------------------

    -----------------------------------------------------------------
    -- Env: VERSION=5.0
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 5.0

    -----------------------------------------------------------------
    -- Env: VERSION=4.0
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 4.0

**Container 1** we see `VERSION=4.2`:

    -----------------------------------------------------------------
    -- circleci-matrix version: 1.0.0
    -- circleci node total: 3
    -- circleci node index: 1
    -----------------------------------------------------------------

    -----------------------------------------------------------------
    -- Env: VERSION=4.2
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 4.2

**Container 2** we see `VERSION=4.1`:

    -----------------------------------------------------------------
    -- circleci-matrix version: 1.0.0
    -- circleci node total: 3
    -- circleci node index: 2
    -----------------------------------------------------------------

    -----------------------------------------------------------------
    -- Env: VERSION=4.1
    -----------------------------------------------------------------
    $ echo 'hi!'
    hi!
    $ echo "Version is $VERSION"
    Version is 4.1


## License

    The MIT License (MIT)

    Copyright (c) 2015 Michael Contento

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
    the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  [circleci-matrix]: https://github.com/michaelcontento/circleci-matrix
  [CircleCI]: https://circleci.com/
  [TravisCI]: https://travis-ci.org/
  [build matrix]: http://docs.travis-ci.com/user/customizing-the-build/#Build-Matrix
  [parallelism]: https://circleci.com/docs/setting-up-parallelism
