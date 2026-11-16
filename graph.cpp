// CSE 101 Programming Assignment: Six Degrees of Kevin Bacon
// Name:
// CruzID:
//
// Implement every function declared in graph.h. You may add your own helper
// functions, but mark them static. Do not use std::queue, std::deque, or
// std::priority_queue: use your own Queue from queue.h.
#include "graph.h"
#include "queue.h"

// ---------------------------------------------------------------------------
// Part 2: building the graph (Section 4)
// ---------------------------------------------------------------------------

int addActor(Graph& g, const std::string& name) {
    (void)g; (void)name;  // TODO
    return 0;
}

int findActor(const Graph& g, const std::string& name) {
    (void)g; (void)name;  // TODO
    return 0;
}

void addMovie(Graph& g, const std::string& title, const std::vector<int>& cast) {
    (void)g; (void)title; (void)cast;  // TODO
}

int costars(const Graph& g, int actor) {
    (void)g; (void)actor;  // TODO
    return 0;
}

int common(const Graph& g, int a, int b) {
    (void)g; (void)a; (void)b;  // TODO
    return 0;
}

// ---------------------------------------------------------------------------
// Part 3: shortest paths (Section 5)
// ---------------------------------------------------------------------------

void bfs(const Graph& g, int source, int blocked, int maxDist,
         std::vector<int>& dist, std::vector<Edge>& parent) {
    (void)g; (void)source; (void)blocked; (void)maxDist; (void)dist; (void)parent;  // TODO
}

std::string formatPath(const Graph& g, int source, int target,
                       const std::vector<Edge>& parent) {
    (void)g; (void)source; (void)target; (void)parent;  // TODO
    return "";
}

// ---------------------------------------------------------------------------
// Part 4: one BFS, different questions (Section 6)
// ---------------------------------------------------------------------------

int within(const Graph& g, int actor, int k) {
    (void)g; (void)actor; (void)k;  // TODO
    return 0;
}

int farthest(const Graph& g, int actor) {
    (void)g; (void)actor;  // TODO
    return 0;
}

int avoid(const Graph& g, int a, int b, int blocked) {
    (void)g; (void)a; (void)b; (void)blocked;  // TODO
    return 0;
}

// ---------------------------------------------------------------------------
// Part 5: new BFS techniques (Section 7)
// ---------------------------------------------------------------------------

int countShortestPaths(const Graph& g, int a, int b) {
    (void)g; (void)a; (void)b;  // TODO
    return 0;
}

int meet(const Graph& g, int a, int b) {
    (void)g; (void)a; (void)b;  // TODO
    return 0;
}
