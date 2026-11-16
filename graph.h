#ifndef GRAPH_H
#define GRAPH_H

#include <string>
#include <unordered_map>
#include <vector>

// ---------------------------------------------------------------------------
// Data structures (do not change)
// ---------------------------------------------------------------------------

// One collaboration seen from one actor: the other actor and a movie they share
struct Edge {
    int actor;   // id of the other actor
    int movie;   // id of the movie they appear in together
};

// The collaboration graph: one vertex per actor, one edge per pair of actors
// who appear in the same movie
struct Graph {
    std::vector<std::string> actorName;            // actor id -> name
    std::unordered_map<std::string, int> actorId;  // name -> actor id
    std::vector<std::string> movieTitle;           // movie id -> title
    std::vector<std::vector<Edge>> adj;            // actor id -> collaborations
};

// ---------------------------------------------------------------------------
// Functions you must implement in graph.cpp (the queue is in queue.h)
// ---------------------------------------------------------------------------

// Part 2: building the graph (Section 4)
int addActor(Graph& g, const std::string& name);    // id of the actor, added if new
int findActor(const Graph& g, const std::string& name);  // id, or -1 if not present
void addMovie(Graph& g, const std::string& title,
              const std::vector<int>& cast);        // connect every pair in the cast
int costars(const Graph& g, int actor);             // number of different co-stars
int common(const Graph& g, int a, int b);           // co-stars shared by a and b

// Part 3: shortest paths (Section 5)
// blocked == -1 means no actor is blocked; maxDist == -1 means no limit
void bfs(const Graph& g, int source, int blocked, int maxDist,
         std::vector<int>& dist, std::vector<Edge>& parent);
std::string formatPath(const Graph& g, int source, int target,
                       const std::vector<Edge>& parent);

// Part 4: one BFS, different questions (Section 6)
int within(const Graph& g, int actor, int k);       // actors 1 to k hops away
int bacon(const Graph& g, int k);                   // REMOVED in version 2: optional, not graded
int farthest(const Graph& g, int actor);            // largest distance from actor
int avoid(const Graph& g, int a, int b, int blocked);  // distance a to b without blocked

// Part 5: new BFS techniques (Section 7)
int countShortestPaths(const Graph& g, int a, int b);  // modulo 1,000,000,007
int meet(const Graph& g, int a, int b);             // actors on some shortest a-b path

#endif
