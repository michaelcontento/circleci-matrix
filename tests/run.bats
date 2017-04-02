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
    circleci-matrix | grep "circleci-matrix version: 1.0.0"
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
    circleci-matrix --config another_config.yml | grep "C 3"
}

@test "load config by name (short option)" {
    circleci-matrix -c another_config.yml | grep "C 3"
}

@test "option: --version" {
    [ "$(circleci-matrix --version)" == "1.0.0" ]
}

@test "option: --help" {
    circleci-matrix --help | grep "Usage: circleci-matrix"
}

@test "option: -h" {
    circleci-matrix --help | grep "Usage: circleci-matrix"
}

@test "should not leak private stuff" {
    circleci-matrix --config no_private_leak.yml
}

@test "support commands even without a env" {
    run circleci-matrix --config command_without_env.yml

    [ $status -eq 0 ]
    echo "$output" | grep 'no env #1'
    echo "$output" | grep 'no env #2'
}

@test "quotation" {
    run circleci-matrix --config quotation.yml

    [ $status -eq 0 ]
    echo "$output" | grep 'SINGLE S'
    echo "$output" | grep 'DOUBLE D'
    echo "$output" | grep 'SINGLE_DOUBLE "SD"'
    echo "$output" | grep "DOUBLE_SINGLE 'DS'"
    echo "$output" | grep "SINGLE_ESCAPED S'E"
    echo "$output" | grep 'DOUBLE_ESCAPED D"E'
}

@test "command arguments" {
    run circleci-matrix --config arguments.yml

    [ $status -eq 0 ]
    echo "$output" | grep 'first: quoted 1'
    echo "$output" | grep 'second: quoted 2'
    echo "$output" | grep 'first: unquoted1'
    echo "$output" | grep 'second: unquoted2'
}

@test "don't fail on first error by default" {
    run circleci-matrix --config fail_on_second.yml

    [ $status -eq 1 ]
    echo "$output" | grep 'first'
    echo "$output" | grep 'third'
}

@test "fail on first" {
    run circleci-matrix --config fail_on_second.yml --stop-on-error

    [ $status -eq 1 ]
    [ $(echo "$output" | grep '^first' | wc -l) -eq 1 ]
    [ $(echo "$output" | grep '^third' | wc -l) -eq 0 ]
}

@test "fail on first (short option)" {
    run circleci-matrix --config fail_on_second.yml -s

    [ $status -eq 1 ]
    [ $(echo "$output" | grep '^first' | wc -l) -eq 1 ]
    [ $(echo "$output" | grep '^third' | wc -l) -eq 0 ]
}

@test "print amount of failed commands" {
    run circleci-matrix --config three_failures.yml
    [ $status -eq 1 ]
    echo "$output" | grep "ERROR: 3 command(s) failed"
}

@test "fail on invalid options" {
    run circleci-matrix --invalid-option
    [ $status -eq 1 ]
    echo "$output" | grep "Unknown option: --invalid-option"
}

@test "cleanup /tmp afterwards" {
    local tempfile=$(mktemp -t circleci_matrix.XXX)
    local tempdir=$(dirname "${tempfile}")

    # Ensure we're clean before
    find "$tempdir" -type f -name 'circleci_matrix*' -delete
    local files=$(find "$tempdir" -type f -name 'circleci_matrix*' | wc -l)
    [ $files -eq 0 ]

    circleci-matrix

    # And after
    local files=$(find "$tempdir" -type f -name 'circleci_matrix*' | wc -l)
    [ $files -eq 0 ]
}

@test "source nvm from ~/nvm/nvm.sh" {
    # Ensure nvm-source where CircleCI will put it
    local remove=0
    if [ ! -f ~/nvm/nvm.sh ]; then
        remove=1
        mkdir -p ~/nvm
        echo "nvm() { echo 'circleci-matrix fake nvm'; }" > ~/nvm/nvm.sh
    fi

    # Use custom path to avoid global installed nvm
    PATH="/usr/bin:/bin" circleci-matrix --config detect_nvm.yml

    # Cleanup if required
    if [ $remove -eq 1 ]; then
        rm -rf ~/nvm
    fi
}

@test "don't treat first argument as CONFIG_FILE" {
    # 1) --stop-on-error is a valid option (--> "invalid argument" error)
    # 2) --stop-on-error is also the first argument
    # 3) before --config/-c we used $1 to select the file
    circleci-matrix --stop-on-error | grep "A 1"
}

@test "don't fail if first element is a comment" {
    circleci-matrix --config comment_first.yml | grep 'after comment'
}

@test "support different identations" {
    circleci-matrix --config different_indentations.yml | grep 'here only 2 - 0'
}

@test "parallelism | 0/3 = process 1, skip 2" {
    export CIRCLE_NODE_TOTAL=3
    export CIRCLE_NODE_INDEX=0
    run circleci-matrix

    [ $status -eq 0 ]
    [ $(echo "$output" | grep 'A 1' | wc -l) -eq 1 ]
    [ $(echo "$output" | grep 'B 1' | wc -l) -eq 1 ]
    [ $(echo "$output" | grep 'A 2' | wc -l) -eq 0 ]
    [ $(echo "$output" | grep 'B 2' | wc -l) -eq 0 ]
}

@test "parallelism | 1/3 = process 2, skip 1" {
    export CIRCLE_NODE_TOTAL=3
    export CIRCLE_NODE_INDEX=1
    run circleci-matrix

    [ $status -eq 0 ]
    [ $(echo "$output" | grep 'A 1' | wc -l) -eq 0 ]
    [ $(echo "$output" | grep 'B 1' | wc -l) -eq 0 ]
    [ $(echo "$output" | grep 'A 2' | wc -l) -eq 1 ]
    [ $(echo "$output" | grep 'B 2' | wc -l) -eq 1 ]
}

@test "parallelism | 3/3 = skip 1, skip 2" {
    export CIRCLE_NODE_TOTAL=3
    export CIRCLE_NODE_INDEX=2
    run circleci-matrix

    [ $status -eq 0 ]
    [ $(echo "$output" | grep 'A 1' | wc -l) -eq 0 ]
    [ $(echo "$output" | grep 'B 1' | wc -l) -eq 0 ]
    [ $(echo "$output" | grep 'A 2' | wc -l) -eq 0 ]
    [ $(echo "$output" | grep 'B 2' | wc -l) -eq 0 ]
}

@test "export circleci | node total" {
    CIRCLE_NODE_TOTAL=5 circleci-matrix --config export_circleci.yml | grep "Node Total: 5"
}

@test "export circleci | node index" {
    CIRCLE_NODE_INDEX=0 circleci-matrix --config export_circleci.yml | grep "Node Index: 0"
}

@test "export circleci | ensure default node total" {
    circleci-matrix --config export_circleci.yml | grep "Node Total: 1"
}

@test "export circleci | ensure default node index" {
    circleci-matrix --config export_circleci.yml | grep "Node Index: 0"
}

@test "missing config file | exit code should be 1" {
    run circleci-matrix --config invalid-config.yml
    [ "$status" -eq 1 ]
}

@test "missing config file | print error message" {
    run circleci-matrix --config invalid-config.yml
    echo "$output" | grep "ERROR: No invalid-config.yml file found!"
}

@test "multiline env" {
    run circleci-matrix --config multiline_env.yml
    [ "$status" -eq 0 ]

    echo "$output" | grep "A=1 B=1"
    echo "$output" | grep "A=2 B=2"
    echo "$output" | grep "A=3 B=3"
    echo "$output" | grep "A=4 B=4"
    echo "$output" | grep "A=5 B=5"
}

@test "strings | dash" {
    run circleci-matrix --config strings_dash.yml
    [ "$status" -eq 0 ]

    echo "$output" | grep "dash-single"
    echo "$output" | grep "dash -2 -1"
    echo "$output" | grep "dash-ignore-trailing -2 -1"

    # Replace \n with _ for easy grepping below
    local nlout=$(echo "$output" | tr '\n' '_')
    echo "$nlout" | grep "_dash-empty_-2_-1_"
}

@test "strings | pipe" {
    run circleci-matrix --config strings_pipe.yml
    [ "$status" -eq 0 ]

    # Replace \n with _ for easy grepping below
    local nlout=$(echo "$output" | tr '\n' '_')

    echo "$nlout" | grep "_pipe_|2_|1_"
    echo "$nlout" | grep "_pipe-empty__|2__|1_"
    echo "$nlout" | grep "_pipe-comment_# foo1_|2_ # foo2_|1_"
    echo "$nlout" | grep "_pipe-ignore-trailing_|2_|1_"
    echo "$nlout" | grep "_pipe: if-ok_"
    [ $(echo "$output" | grep 'pipe-start-comment' | wc -l) -eq 0 ]
}

@test "strings | bracket" {
    run circleci-matrix --config strings_bracket.yml
    [ "$status" -eq 0 ]

    # Replace \n with _ for easy grepping below
    local nlout=$(echo "$output" | tr '\n' '_')

    echo "$nlout" | grep "_bracket_>2_>1_"
    echo "$nlout" | grep "_bracket-empty__>2__>1_"
    echo "$nlout" | grep "_bracket-comment_# foo1_>2_ # foo2_>1_"
    echo "$nlout" | grep "_bracket-ignore-trailing_>2_>1_"
    echo "$nlout" | grep "_bracket: if-ok_"
    [ $(echo "$output" | grep 'bracket-start-comment' | wc -l) -eq 0 ]
}

@test "should support spaces in single quoted variables" {
    circleci-matrix --config whitespace_support.yml | grep "^double quoted$"
}

@test "should support spaces in double quoted variables" {
    circleci-matrix --config whitespace_support.yml | grep "^single quoted$"
}
