// CSE 101 Programming Assignment: Six Degrees of Kevin Bacon
// Name:
// CruzID:
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "graph.h"

// ===========================================================================
// PROVIDED: answering one query. Do not change this function.
// words holds the words of one line of the input file, in order.
// ===========================================================================
static std::string number(int x) { return std::to_string(x); }

static std::string answerQuery(const Graph& g, const std::vector<std::string>& words) {
    const std::string& kind = words[0];

    if (kind == "COSTARS" || kind == "FARTHEST" || kind == "WITHIN") {
        int a = findActor(g, words[1]);
        if (a == -1) return "-1";
        if (kind == "COSTARS") return number(costars(g, a));
        if (kind == "FARTHEST") return number(farthest(g, a));
        return number(within(g, a, std::stoi(words[2])));
    }

    if (kind == "COMMON" || kind == "COUNT" || kind == "MEET" || kind == "AVOID") {
        int a = findActor(g, words[1]);
        int b = findActor(g, words[2]);
        if (a == -1 || b == -1) return "-1";
        if (kind == "COMMON") return number(common(g, a, b));
        if (kind == "COUNT") return number(countShortestPaths(g, a, b));
        if (kind == "MEET") return number(meet(g, a, b));
        return number(avoid(g, a, b, findActor(g, words[3])));  // C not present: nothing blocked
    }

    // No keyword: the line is ACTOR1 ACTOR2, and the answer is a shortest path
    int a = findActor(g, words[0]);
    int b = findActor(g, words[1]);
    if (a == -1 || b == -1) return "Not present";
    std::vector<int> dist;
    std::vector<Edge> parent;
    bfs(g, a, -1, -1, dist, parent);
    if (dist[b] == -1) return "Not present";
    return formatPath(g, a, b, parent);
}

// ===========================================================================
// YOUR CODE: reading the data file, reading the input file, writing output
// ===========================================================================

// Reads the data file at path into g and returns true, or returns false if the
// file cannot be opened. Each line is a movie title followed by the names of
// its actors, separated by spaces (Section 8.1).
static bool loadData(Graph& g, const std::string& path) {
    // TODO: open the file; for each line, read the title and the actor names,
    // turn each name into an id with addActor, then call addMovie
    (void)g; (void)path;
    return false;
}

int main(int argc, char* argv[]) {
    // TODO: check the command line (Section 9)
    (void)argc; (void)argv;

    Graph g;
    if (!loadData(g, "cleaned_movielist.txt")) {
        // TODO: print the error message and exit (Section 9)
    }

    // TODO: open the input file argv[1] and the output file argv[2]

    // TODO: for each line of the input file:
    //   - split it into words, in order
    //   - skip the line if it has no words
    //   - write answerQuery(g, words) and a newline to the output file
    std::vector<std::string> words;
    if (!words.empty()) answerQuery(g, words);

    return 0;
}
