#!/usr/bin/env bats

setup() {
    cd $BATS_TEST_DIRNAME
    unset CIRCLE_NODE_TOTAL
    unset CIRCLE_NODE_INDEX
}

circleci-matrix() {
    $BATS_TEST_DIRNAME/../src/circleci-matrix.sh $@
}

@test "print version" {
    circleci-matrix | grep "circleci-matrix version: 0.2.0"
}

@test "print node total" {
    CIRCLE_NODE_TOTAL=5 circleci-matrix | grep "circleci node total: 5"
}

@test "print node index" {
    CIRCLE_NODE_INDEX=5 circleci-matrix | grep "circleci node index: 5"
}

@test "use default node total" {
    circleci-matrix | grep "circleci node total: 1"
}

@test "use default node index" {
    circleci-matrix | grep "circleci node index: 0"
}

@test "should run both commands for env 1" {
    circleci-matrix | grep "A 1"
    circleci-matrix | grep "B 1"
}

@test "should run both commands for env 2" {
    circleci-matrix | grep "A 2"
    circleci-matrix | grep "B 2"
}

@test "should ignore comment lines" {
    grep 'C $VERSION' .circleci-matrix.yml
    local matches=$(circleci-matrix | grep 'C 1' | wc -l)
    [ $matches -eq 0 ]
}

@test "load config by name" {
    circleci-matrix another-config.yml | grep "C 3"
}

@test "should not leak private stuff" {
    circleci-matrix no-private-leak.yml
}

@test "quotation" {
    run circleci-matrix quotation.yml

    [ $status -eq 0 ]
    [ $(echo $output | grep 'SINGLE S') ]
    [ $(echo $output | grep 'DOUBLE D') ]
    [ $(echo $output | grep 'SINGLE_DOUBLE "SD"') ]
    [ $(echo $output | grep "DOUBLE_SINGLE 'DS'") ]
    [ $(echo $output | grep "SINGLE_ESCAPED S'E") ]
    [ $(echo $output | grep 'DOUBLE_ESCAPED D"E') ]
}

@test "command arguments" {
    run circleci-matrix arguments.yml

    [ $status -eq 0 ]
    [ $(echo $output | grep 'first: quoted 1') ]
    [ $(echo $output | grep 'second: quoted 2') ]
    [ $(echo $output | grep 'first: unquoted1') ]
    [ $(echo $output | grep 'second: unquoted2') ]
}

@test "parallelism | 0/3 = process 1, skip 2" {
    export CIRCLE_NODE_TOTAL=3
    export CIRCLE_NODE_INDEX=0
    run circleci-matrix

    [ $status -eq 0 ]
    [ $(echo $output | grep 'A 1' | wc -l) -eq 1 ]
    [ $(echo $output | grep 'B 1' | wc -l) -eq 1 ]
    [ $(echo $output | grep 'A 2' | wc -l) -eq 0 ]
    [ $(echo $output | grep 'B 2' | wc -l) -eq 0 ]
}

@test "parallelism | 1/3 = process 2, skip 1" {
    export CIRCLE_NODE_TOTAL=3
    export CIRCLE_NODE_INDEX=1
    run circleci-matrix

    [ $status -eq 0 ]
    [ $(echo $output | grep 'A 1' | wc -l) -eq 0 ]
    [ $(echo $output | grep 'B 1' | wc -l) -eq 0 ]
    [ $(echo $output | grep 'A 2' | wc -l) -eq 1 ]
    [ $(echo $output | grep 'B 2' | wc -l) -eq 1 ]
}

@test "parallelism | 3/3 = skip 1, skip 2" {
    export CIRCLE_NODE_TOTAL=3
    export CIRCLE_NODE_INDEX=2
    run circleci-matrix

    [ $status -eq 0 ]
    [ $(echo $output | grep 'A 1' | wc -l) -eq 0 ]
    [ $(echo $output | grep 'B 1' | wc -l) -eq 0 ]
    [ $(echo $output | grep 'A 2' | wc -l) -eq 0 ]
    [ $(echo $output | grep 'B 2' | wc -l) -eq 0 ]
}

@test "export circleci | node total" {
    CIRCLE_NODE_TOTAL=5 circleci-matrix export-circleci.yml | grep "Node Total: 5"
}

@test "export circleci | node index" {
    CIRCLE_NODE_INDEX=0 circleci-matrix export-circleci.yml | grep "Node Index: 0"
}

@test "export circleci | ensure default node total" {
    circleci-matrix export-circleci.yml | grep "Node Total: 1"
}

@test "export circleci | ensure default node index" {
    circleci-matrix export-circleci.yml | grep "Node Index: 0"
}

@test "missing config file | exit code should be 1" {
    run circleci-matrix invalid-config.yml
    [ "$status" -eq 1 ]
}

@test "missing config file | print error message" {
    run circleci-matrix invalid-config.yml
    echo $output | grep "ERROR: No invalid-config.yml file found!"
}
