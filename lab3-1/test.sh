#!/bin/bash
lab_3_1=$(realpath `dirname $0`)
build="$lab_3_1/build"
testcase="$lab_3_1/testcase"
test_build="$testcase/build"

tests=($testcase/*.cminus)
tests_count=${#tests[@]}

GCC="gcc -x c -Wno-implicit-function-declaration"
LDFLAGS="-L$build -lcminus_io"
CMINUSC="env LIBRARY_PATH="$build" $build/cminusc"

COLOR_GREEN=$'\x1b[32m'
COLOR_RED=$'\x1b[31m'
COLOR_RESET=$'\x1b[m'

out_path() {
    printf "$(realpath `dirname $1`)/build/$(basename $1)-$2"
}

get_input() {
    local input_cnt=$(grep -c "input()" $1)
    for ((i=0; i<$input_cnt; i++)); do
        echo $(($RANDOM%10))
    done
}

run_case() {
    local name=${tests[$i]}
    echo -n "Running testcase `basename $name` ... "
    $CMINUSC -o "$(out_path $name cminusc)" $name >/dev/null 2>&1 |:
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        fail_count=$(($fail_count+1))
        echo "${COLOR_RED}compile error${COLOR_RESET}"
        return
    fi
    if [[ ! -f $(out_path $name cminusc) ]]; then
        fail_count=$(($fail_count+1))
        echo "${COLOR_RED}no executable${COLOR_RESET}"
        return
    fi
    $GCC -o "$(out_path $name gcc)" $name $LDFLAGS
    local in=$(get_input $name)
    local cmi_cmd=$(out_path $name cminusc)
    local cmi_out=$($cmi_cmd <<<"$in")
    local cmi_ret=$?
    local gcc_cmd=$(out_path $name gcc)
    local gcc_out=$($gcc_cmd <<<"$in")
    local gcc_ret=$?
    diff <(echo $cmi_out) <(echo $gcc_out) >/dev/null 2>&1

    if [[ $? != 0 ]]; then
        echo "${COLOR_RED}output error${COLOR_RESET}"
        fail_count=$(($fail_count+1))
        return
    fi
    if [[ $gcc_ret != $cmi_ret ]]; then
        echo "${COLOR_RED}return code error${COLOR_RESET}"
        fail_count=$(($fail_count+1))
        return
    fi
    echo "${COLOR_GREEN}ok${COLOR_RESET}"
}

build() {
    [[ -d build ]] || {
        mkdir -p $build
        (cd $build && cmake ..)
    }
    (cd $build && make)
}

main() {
    [[ -d "$test_build" ]] && rm -r $test_build
    mkdir -p $test_build
    fail_count=0
    # build
    for ((i=0; i<$tests_count; i++)); do
        run_case $i
    done
    echo
    echo "Run $tests_count tests, $fail_count fails."
}

trap "" SEGV

main
