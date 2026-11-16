#!/usr/bin/env bash
# Local test runner for CSE 101 Programming Assignment: Six Degrees of Kevin Bacon.
#
#   ./run_tests.sh              build, then run every test
#   ./run_tests.sh 05           run only tests whose name contains "05"
#   ./run_tests.sh count        run only tests whose name contains "count"
#   ./run_tests.sh --list       list all tests without running them
#
# Each test is a folder in tests/. There are two kinds:
#
#   Function tests call one graph.h function directly. The folder holds:
#     unit            the name of the test in scripts/unit_tests.cpp
#
#   Query tests run your whole program. The folder holds:
#     input.txt       the input file (the queries)
#     expected.txt    the expected output file
#     data            which data file the program reads: full (cleaned_movielist.txt
#                     in this folder) or small (small/cleaned_movielist.txt)
#     cmd             the arguments passed to ./sixdegrees; {input} and {output}
#                     stand for the test's input.txt and your output file
#     expected_exit   (optional) the expected exit status; 0 if missing
#     expected_stderr (optional) the exact expected standard error; not checked if missing
#
#   Every folder also has a part and a description.
#
# A path answer is correct if it is ANY shortest path, so your path may differ from
# the one in expected.txt and still pass (scripts/check_paths.py checks it).
#
# Your output file for each query test is saved in test_output/<test>.txt,
# and its standard error in test_output/<test>.stderr.txt.
# These are the visible tests only. Gradescope also runs hidden tests.
#
# Works in a Codespace, on macOS (including its built-in bash 3.2), and on
# Windows in WSL or Git Bash.

cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"

TIME_LIMIT=10
MAX_DIFF_LINES=40

# Stop a test that runs too long. macOS has no `timeout` command, so fall back
# to gtimeout (Homebrew coreutils) or perl, which every Mac and Git Bash has.
if command -v timeout >/dev/null 2>&1; then
    LIMIT="timeout $TIME_LIMIT"; TIMEOUT_CODE=124
elif command -v gtimeout >/dev/null 2>&1; then
    LIMIT="gtimeout $TIME_LIMIT"; TIMEOUT_CODE=124
elif command -v perl >/dev/null 2>&1; then
    LIMIT="perl -e 'alarm shift; exec @ARGV' $TIME_LIMIT"; TIMEOUT_CODE=142
else
    LIMIT=""; TIMEOUT_CODE=124
    echo "Note: no timeout command found, so tests run without a time limit."
fi

if command -v python3 >/dev/null 2>&1; then PYTHON=python3; else PYTHON=python; fi

if [ -t 1 ]; then
    RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; BOLD=""; RESET=""
fi

tests=()
for dir in tests/*/; do
    tests+=("$(basename "$dir")")
done

if [ "$1" = "--list" ]; then
    for t in "${tests[@]}"; do
        printf "%-36s %s\n" "$t" "$(cat "tests/$t/description" 2>/dev/null)"
    done
    exit 0
fi

filter="$1"

echo "${BOLD}Building...${RESET}"
if ! make --no-print-directory all; then
    echo
    echo "${RED}Build failed. Fix the errors above, then run the tests again.${RESET}"
    exit 1
fi
mkdir -p test_output
UNIT_BIN=test_output/unit_tests
UNIT_OK=1
if ! g++ -std=c++17 -O2 -I. -o "$UNIT_BIN" scripts/unit_tests.cpp graph.cpp queue.cpp 2> test_output/unit_tests.build.txt; then
    UNIT_OK=0
    echo "${RED}The function tests do not compile with your graph.cpp and queue.cpp:${RESET}"
    head -20 test_output/unit_tests.build.txt
fi
echo

passed=0; failed=0; ran=0
# Per-part totals, kept in parallel arrays (bash 3.2 has no associative arrays).
part_names=(); part_pass=(); part_total=()

for t in "${tests[@]}"; do
    if [ -n "$filter" ] && [[ "$t" != *"$filter"* ]]; then continue; fi
    dir="tests/$t"
    ran=$((ran + 1))

    part="$(tr -d '\r' < "$dir/part" 2>/dev/null)"
    [ -n "$part" ] || part="Other"
    pi=0
    while [ $pi -lt ${#part_names[@]} ] && [ "${part_names[$pi]}" != "$part" ]; do
        pi=$((pi + 1))
    done
    if [ $pi -eq ${#part_names[@]} ]; then
        part_names[$pi]="$part"; part_pass[$pi]=0; part_total[$pi]=0
    fi
    part_total[$pi]=$((part_total[$pi] + 1))

    problem=""; details=""; shown_cmd=""

    if [ -f "$dir/unit" ]; then
        # ---- function test ----
        unit="$(tr -d '\r\n' < "$dir/unit")"
        shown_cmd="function test $unit"
        if [ $UNIT_OK -eq 0 ]; then
            problem="the function tests did not compile"
        else
            result="$(eval "$LIMIT $UNIT_BIN '$unit'" 2>&1)"; code=$?
            if [ -n "$LIMIT" ] && [ $code -eq $TIMEOUT_CODE ]; then
                problem="timed out after ${TIME_LIMIT}s (infinite loop?)"
            elif [ $code -ge 128 ]; then
                problem="crashed (signal $((code - 128)); often an index out of range)"
            elif [ "$result" != "PASS" ]; then
                problem="${result#FAIL: }"
            fi
        fi
    else
        # ---- query test: run the whole program ----
        data="$(tr -d '\r\n' < "$dir/data" 2>/dev/null)"
        if [ "$data" = "small" ]; then rundir="$ROOT/small"; else rundir="$ROOT"; fi
        out="$ROOT/test_output/$t.txt"
        err="$ROOT/test_output/$t.stderr.txt"
        rm -f "$out"
        args="$(tr -d '\r\n' < "$dir/cmd")"
        args="${args//\{input\}/\"$ROOT/$dir/input.txt\"}"
        args="${args//\{output\}/\"$out\"}"
        if [ "$data" = "small" ]; then
            shown_cmd="cd small && ../sixdegrees $(tr -d '\r\n' < "$dir/cmd" | sed "s#{input}#../$dir/input.txt#; s#{output}#../test_output/$t.txt#")   (the 13-movie data file)"
        else
            shown_cmd="./sixdegrees $(tr -d '\r\n' < "$dir/cmd" | sed "s#{input}#$dir/input.txt#; s#{output}#test_output/$t.txt#")"
        fi
        expected_exit=0
        [ -f "$dir/expected_exit" ] && expected_exit="$(tr -d '\r\n' < "$dir/expected_exit")"
        [ -n "$expected_exit" ] || expected_exit=0

        # Run inside the folder that holds the data file the test uses.
        (cd "$rundir" && eval "$LIMIT \"$ROOT/sixdegrees\" $args") > "test_output/$t.stdout.txt" 2> "$err"
        code=$?

        if [ -n "$LIMIT" ] && [ $code -eq $TIMEOUT_CODE ]; then
            problem="timed out after ${TIME_LIMIT}s (too slow, or an infinite loop)"
        elif [ $code -ge 128 ]; then
            problem="crashed (signal $((code - 128)); often an index out of range)"
        elif [ "$code" != "$expected_exit" ]; then
            problem="exit status $code, expected $expected_exit"
        elif [ -f "$dir/expected_stderr" ] && \
             ! diff -q --strip-trailing-cr "$dir/expected_stderr" "$err" >/dev/null; then
            problem="standard error differs from expected"
            details="$(diff -u --strip-trailing-cr --label "expected" --label "your standard error" \
                "$dir/expected_stderr" "$err" | head -n $MAX_DIFF_LINES)"
        elif [ -f "$dir/expected.txt" ]; then
            if [ ! -f "$out" ]; then
                problem="your program did not create the output file"
            elif [ -s "test_output/$t.stdout.txt" ]; then
                problem="your program printed to std::cout; answers must go to the output file"
            elif ! diff -q --strip-trailing-cr "$dir/expected.txt" "$out" >/dev/null; then
                # Different text can still be correct: any shortest path is accepted.
                if [ "$data" = "small" ]; then datafile=small/cleaned_movielist.txt; else datafile=cleaned_movielist.txt; fi
                details="$($PYTHON scripts/check_paths.py "$datafile" "$dir/input.txt" "$dir/expected.txt" "$out")"
                [ -n "$details" ] && problem="output differs from expected"
            fi
        fi
        rm -f "test_output/$t.stdout.txt"
    fi

    if [ -z "$problem" ]; then
        passed=$((passed + 1))
        part_pass[$pi]=$((part_pass[$pi] + 1))
        echo "${GREEN}PASS${RESET}  $t"
    else
        failed=$((failed + 1))
        echo "${RED}FAIL${RESET}  $t: $problem"
        echo "      $(cat "$dir/description" 2>/dev/null)"
        echo "      command: $shown_cmd"
        if [ "$problem" = "output differs from expected" ]; then
            echo "      ${YELLOW}--- lines starting with - are expected, + are your output${RESET}"
            echo "$details" | sed 's/^      //; s/^/      /'
        elif [ -n "$details" ]; then
            echo "      ${YELLOW}--- lines starting with - are expected, + are what your program printed to std::cerr${RESET}"
            echo "$details" | sed 's/^/      /'
        fi
        echo
    fi
done

if [ $ran -eq 0 ]; then
    echo "No tests match \"$filter\". Use ./run_tests.sh --list to see test names."
    exit 1
fi

echo
echo "${BOLD}Summary${RESET}"
pi=0
while [ $pi -lt ${#part_names[@]} ]; do
    printf "  %-40s %d/%d passed\n" "${part_names[$pi]}" "${part_pass[$pi]}" "${part_total[$pi]}"
    pi=$((pi + 1))
done
echo "  ----------------------------------------------------"
printf "  %-40s %d/%d passed\n" "Total" "$passed" "$ran"
echo
if [ $failed -eq 0 ]; then
    if [ -n "$filter" ]; then
        echo "${GREEN}${BOLD}All $ran selected tests passed.${RESET} Run ./run_tests.sh with no arguments to run every test."
    else
        echo "${GREEN}${BOLD}All $ran tests passed!${RESET}"
        echo "Before submitting: remove any debug prints, fill in citations.md, and push your work."
    fi
else
    echo "${RED}${BOLD}$failed of $ran tests failed.${RESET} Scroll up to see the differences for each failed test."
fi
echo "Your outputs are saved in test_output/. Gradescope also runs hidden tests."

[ $failed -eq 0 ]
