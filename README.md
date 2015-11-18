[![Circle CI](https://circleci.com/gh/winksaville/circleci-matrix.svg?style=shield)](https://circleci.com/gh/winksaville/circleci-matrix)
[circleci-matrix][]
===================

Small utility to mirror [TravisCI][]'s [build matrix][] on [CircleCI][].

## Installation

Add circleci-matrix as a submodule to your project or you can just
cricleci-martrix.sh to your project somewhere convenient.

## Usage

Then add your build matrix in a new file circle-matrix.yml
or you can pass the name to circle-matrix.sh.
```
env:
    - VERSION=5.0
    - VERSION=4.2
    - VERSION=4.1
    - VERSION=4.0

command:
    - echo 'hi!'
    - echo "Version is $VERSION"
```
Now you're ready to execute it locally we'll execute
example-matrix.yml:
```
    $ ./circleci-matrix.sh circle-matrix.yml
```
Or add it to your circle.yml file, for instance:
```
test:
  override:
    - ./circle-matrix.sh circle-matrix.yml
```
In either case the result should be:

```
INFO: Circle Matrix Version: 0.2.0
INFO: Circle Node Total: 4
INFO: Circle Node Index: 0

hi!
Version is 5.0

hi!
Version is 4.2

hi!
Version is 4.1

hi!
Version is 4.0
```
All commands have been executed with the right value in `$VERSION`.

## Parallelism

[CircleCI][]'s [parallelism][] is supported out of the box! Have a look at the following
example where I set the `CIRCLE_NODE_TOTAL`and CIRCLE_NODE_INDEX manually
first to 2 and 0 then to 2 and 1:
```
$ CIRCLE_NODE_TOTAL=2 CIRCLE_NODE_INDEX=0 ./circle-matrix.sh circle-matrix.yml
INFO: Circle Matrix Version: 0.2.0
INFO: Circle Node Total: 2
INFO: Circle Node Index: 0

hi!
Version is 5.0
hi!
Version is 4.1

$ CIRCLE_NODE_TOTAL=2 CIRCLE_NODE_INDEX=1 ./circle-matrix.sh circle-matrix.yml
INFO: Circle Matrix Version: 0.2.0
INFO: Circle Node Total: 2
INFO: Circle Node Index: 1

hi!
Version is 4.2
hi!
Version is 4.0
```
And here is the output when circleci runs our circle.yml file with 3 containers

Container 0 we see VERSION=5.0 and Version=4.0:
```
./circle-matrix.sh circle-matrix.yml
INFO: Circle Matrix Version: 0.2.0
INFO: Circle Node Total: 3
INFO: Circle Node Index: 0
INFO: Detected CircleCI environment

hi!
Version is 5.0
hi!
Version is 4.0
```
Container 1 we see VERSION=4.2:
```
./circle-matrix.sh circle-matrix.yml
INFO: Circle Matrix Version: 0.2.0
INFO: Circle Node Total: 3
INFO: Circle Node Index: 1
INFO: Detected CircleCI environment

hi!
Version is 4.2
```
Container 2 we see VERSION=4.1:
```
./circle-matrix.sh circle-matrix.yml
INFO: Circle Matrix Version: 0.2.0
INFO: Circle Node Total: 3
INFO: Circle Node Index: 2
INFO: Detected CircleCI environment

hi!
Version is 4.1
```
  [circleci-matrix]: https://github.com/winksaville/circleci-matrix
  [CircleCI]: https://circleci.com/
  [TravisCI]: https://travis-ci.org/
  [build matrix]: http://docs.travis-ci.com/user/customizing-the-build/#Build-Matrix
  [parallelism]: https://circleci.com/docs/setting-up-parallelism
