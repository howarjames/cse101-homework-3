#!/usr/bin/env bash
# Checks the assignment rules before and after compiling. Run automatically by `make`.
#
#   scripts/check_rules.sh source                 check the source files (before compiling)
#   scripts/check_rules.sh symbols main.o graph.o queue.o   check the compiled object files
#
# Do not modify this file. Gradescope runs the original.

GRAPH_H_SHA256="0ee50e279cb93399203ad8002253e90855e87b9b2659b402681aa0e007213344"
QUEUE_H_SHA256="f7e8932e543b562d8d92147cd1f52015ea0f3047fbc65f01de70a30d5cabb2b2"
ALLOWED_INCLUDES="string iostream fstream sstream vector unordered_map cstdlib graph.h queue.h"
QUEUE_FUNCTIONS="enqueue dequeue isEmpty clearQueue"
GRAPH_FUNCTIONS="addActor findActor addMovie costars common bfs formatPath within farthest avoid countShortestPaths meet"
# Removed in version 2 but still declared in graph.h: allowed in graph.cpp, never required.
OPTIONAL_GRAPH_FUNCTIONS="bacon"

fail() {
    echo "" >&2
    echo "RULE BROKEN: $1" >&2
    echo "FIX: $2" >&2
    echo "" >&2
    exit 1
}

# Remove comments and string/char literals so they are not mistaken for code.
strip_code() {
    perl -0777 -pe 's{//[^\n]*}{}g; s{/\*.*?\*/}{}gs; s{"(?:\\.|[^"\\\n])*"}{""}g; s{'"'"'(?:\\.|[^'"'"'\\\n])*'"'"'}{'"'"''"'"'}g' "$1"
}

# Remove only comments (keeps string literals, so quoted #include names stay readable).
strip_comments() {
    perl -0777 -pe 's{//[^\n]*}{}g; s{/\*.*?\*/}{}gs' "$1"
}

check_source() {
    # 1. Exactly the allowed source files
    for f in *.cpp *.cc *.cxx *.h *.hpp *.hh; do
        [ -e "$f" ] || continue
        case "$f" in
            main.cpp|graph.cpp|queue.cpp|graph.h|queue.h) ;;
            *) fail "Extra source file '$f'." \
                    "Write your code in main.cpp, graph.cpp, and queue.cpp only. Delete or rename '$f'." ;;
        esac
    done
    [ -f main.cpp ]  || fail "main.cpp is missing." "Create main.cpp in the same folder as the Makefile."
    [ -f graph.cpp ] || fail "graph.cpp is missing." "Create graph.cpp in the same folder as the Makefile."
    [ -f queue.cpp ] || fail "queue.cpp is missing." "Create queue.cpp in the same folder as the Makefile."
    [ -f graph.h ]   || fail "graph.h is missing." "Restore graph.h from the starter repository."
    [ -f queue.h ]   || fail "queue.h is missing." "Restore queue.h from the starter repository."

    # 2. graph.h and queue.h are unchanged
    for h in graph.h queue.h; do
        actual=$( (sha256sum "$h" 2>/dev/null || shasum -a 256 "$h") | awk '{print $1}')
        want=$GRAPH_H_SHA256; [ "$h" = queue.h ] && want=$QUEUE_H_SHA256
        [ "$actual" = "$want" ] || \
            fail "$h has been modified." \
                 "Restore the original $h from the starter repository (git checkout -- $h)."
    done

    for f in main.cpp graph.cpp queue.cpp; do
        code=$(strip_code "$f")

        # 3. Only allowed #includes, each written as a plain #include <name> or #include "name"
        #    (no macros, paths, #include_next, or #import).
        while read -r line; do
            [ -z "$line" ] && continue
            inc=$(printf '%s\n' "$line" | sed -nE 's/^[[:space:]]*#[[:space:]]*include[[:space:]]*[<"]([A-Za-z_.]+)[>"][[:space:]]*$/\1/p')
            ok=0
            for a in $ALLOWED_INCLUDES; do [ -n "$inc" ] && [ "$inc" = "$a" ] && ok=1; done
            [ $ok -eq 1 ] || fail "$f has a disallowed include: $(printf '%s' "$line" | tr -s ' \t' ' ')" \
                "Use only: <string> <iostream> <fstream> <sstream> <vector> <unordered_map> <cstdlib> \"graph.h\" \"queue.h\", each on its own #include line."
        done < <(strip_comments "$f" | grep -E '^[[:space:]]*#[[:space:]]*(include|include_next|import)')

        # 4. No library queue types
        if printf '%s\n' "$code" | grep -Eq '\b(queue|deque|priority_queue)[[:space:]]*<'; then
            fail "$f uses std::queue or std::deque." \
                 "Use your own Queue from queue.h (Section 3)."
        fi
    done

    # 5. main() only in main.cpp
    strip_code main.cpp  | grep -Eq '\bmain[[:space:]]*\(' || \
        fail "main.cpp does not define main()." "Put main() in main.cpp."
    for f in graph.cpp queue.cpp; do
        strip_code "$f" | grep -Eq '\bint[[:space:]]+main[[:space:]]*\(' && \
            fail "$f defines main()." "Move main() to main.cpp."
    done
    echo "Rule check passed."
    exit 0
}

check_symbols() {
    main_o="$1"; graph_o="$2"; queue_o="$3"
    # Global (non-static) functions defined in each object file, by name
    # Compiler-generated functions (like an implicit destructor) are weak symbols and
    # are skipped: GNU nm marks them W, and macOS nm -m marks them "weak external".
    globals() {
        if [ "$(uname)" = Darwin ]; then
            # macOS adds a leading underscore to every symbol, and nm -m does not demangle.
            nm -m --defined-only "$1" | grep '(__TEXT,__text) external ' |
                sed -E 's/.*\(__TEXT,__text\) external //; s/ \(.*\)$//; s/^_//' | c++filt -n
        else
            nm -C --defined-only "$1" | awk '$2=="T"{ $1=""; $2=""; sub(/^  /,""); print }'
        fi | sed -E 's/\[abi:[^]]*\]//g; s/\(.*//; s/^_main$/main/'
    }
    for sym in $(globals "$main_o"); do
        [ "$sym" = "main" ] && continue
        fail "main.cpp defines a non-static function '$sym'." \
             "Mark helper functions static. The graph.h functions go in graph.cpp, the queue.h functions in queue.cpp."
    done
    for sym in $(globals "$queue_o"); do
        for fn in $GRAPH_FUNCTIONS $OPTIONAL_GRAPH_FUNCTIONS; do
            [ "$sym" = "$fn" ] && fail "queue.cpp defines the graph function '$sym'." \
                "Move $sym to graph.cpp."
        done
        ok=0
        for fn in $QUEUE_FUNCTIONS; do [ "$sym" = "$fn" ] && ok=1; done
        [ $ok -eq 1 ] || fail "queue.cpp defines a non-static function '$sym'." \
            "Mark helper functions static, and put only the queue.h functions in queue.cpp."
    done
    for sym in $(globals "$graph_o"); do
        for fn in $QUEUE_FUNCTIONS; do
            [ "$sym" = "$fn" ] && fail "graph.cpp defines the queue function '$sym'." \
                "Move $sym to queue.cpp; graph.cpp uses the queue through #include \"queue.h\"."
        done
        ok=0
        for fn in $GRAPH_FUNCTIONS $OPTIONAL_GRAPH_FUNCTIONS; do [ "$sym" = "$fn" ] && ok=1; done
        [ $ok -eq 1 ] || fail "graph.cpp defines a non-static function '$sym'." \
            "Mark helper functions static."
    done
    # graph.cpp must use the student's own Queue (it calls enqueue and dequeue from queue.cpp).
    if [ "$(uname)" = Darwin ]; then
        used=$(nm -u "$graph_o" | sed -E 's/^_//' | c++filt -n)
    else
        used=$(nm -C -u "$graph_o")
    fi
    # Not fatal here, so the starter still builds while you work on Part 1. Gradescope gives no
    # credit for the BFS-based tests (Parts 3-5 and the queries that need BFS) until it does.
    for fn in enqueue dequeue; do
        printf '%s\n' "$used" | grep -Eq "(^|[[:space:]])$fn\(" || {
            echo "NOTE: graph.cpp does not call $fn yet. Your BFS must use your own Queue from queue.h;" >&2
            echo "      Gradescope gives no credit for BFS-based tests until graph.cpp calls enqueue and dequeue." >&2
            break
        }
    done
    # Every graph.h function is defined in graph.cpp with exactly the declared parameters:
    # link a program that takes the address of each one with its exact type.
    tmp=$(mktemp -d)
    cat > "$tmp/signatures.cpp" <<'SIG'
#include "graph.h"
#include "queue.h"
int main() {
    void (*f1)(Queue&, int) = enqueue;
    int (*f2)(Queue&) = dequeue;
    bool (*f3)(const Queue&) = isEmpty;
    void (*f4)(Queue&) = clearQueue;
    int (*f5)(Graph&, const std::string&) = addActor;
    int (*f6)(const Graph&, const std::string&) = findActor;
    void (*f7)(Graph&, const std::string&, const std::vector<int>&) = addMovie;
    int (*f8)(const Graph&, int) = costars;
    int (*f9)(const Graph&, int, int) = common;
    void (*f10)(const Graph&, int, int, int, std::vector<int>&, std::vector<Edge>&) = bfs;
    std::string (*f11)(const Graph&, int, int, const std::vector<Edge>&) = formatPath;
    int (*f12)(const Graph&, int, int) = within;
    int (*f13)(const Graph&, int) = farthest;
    int (*f14)(const Graph&, int, int, int) = avoid;
    int (*f15)(const Graph&, int, int) = countShortestPaths;
    int (*f16)(const Graph&, int, int) = meet;
    void* all[] = {(void*)f1, (void*)f2, (void*)f3, (void*)f4, (void*)f5, (void*)f6, (void*)f7,
                   (void*)f8, (void*)f9, (void*)f10, (void*)f11, (void*)f12, (void*)f13, (void*)f14,
                   (void*)f15, (void*)f16};
    for (void* p : all) if (!p) return 1;
    return 0;
}
SIG
    if ! g++ -std=c++17 -I. -o "$tmp/signatures" "$tmp/signatures.cpp" "$graph_o" "$queue_o" > "$tmp/log" 2>&1; then
        missing=$(grep -oE "undefined reference to \`[a-zA-Z]+" "$tmp/log" | sed 's/.*`//' | sort -u | tr '\n' ' ')
        rm -rf "$tmp"
        fail "graph.cpp or queue.cpp does not define: ${missing:-one of the required functions}" \
             "Implement every function with exactly the names and parameters in graph.h and queue.h."
    fi
    rm -rf "$tmp"
    exit 0
}

cd "$(dirname "$0")/.." || exit 1

case "$1" in
    source)  check_source ;;
    symbols) check_symbols "$2" "$3" "$4" ;;
    *) echo "usage: $0 source | symbols main.o graph.o queue.o" >&2; exit 2 ;;
esac
