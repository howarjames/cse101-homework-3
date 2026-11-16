// Function tests: each test calls one graph.h function directly. Used by run_tests.sh.
// These are the visible tests; Gradescope also runs hidden tests for every function.
// Graphs and queues are built by the test itself (not with your addActor/addMovie),
// so a bug in one function does not make the tests of another function fail.
//
//   ./unit_tests <test-name>      run one test; prints PASS or FAIL: <reason>
#include <iostream>
#include <string>
#include <vector>
#include "graph.h"
#include "queue.h"

static std::string g_fail;
#define CHECK(cond, msg) do { if (!(cond)) { g_fail = msg; return; } } while (0)

// ---------- helpers that build queues and graphs without your code ----------
static Queue make_queue(int capacity, int front, const std::vector<int>& values) {
    Queue q;
    q.data.assign(capacity, -99);
    q.front = front;
    q.count = (int)values.size();
    for (int i = 0; i < q.count; i++) q.data[(front + i) % capacity] = values[i];
    return q;
}
static bool holds(const Queue& q, const std::vector<int>& values) {
    if (q.count != (int)values.size() || (int)q.data.size() < q.count) return false;
    if (q.count > 0 && (q.front < 0 || q.front >= (int)q.data.size())) return false;
    for (int i = 0; i < q.count; i++)
        if (q.data[(q.front + i) % q.data.size()] != values[i]) return false;
    return true;
}
static int actor(Graph& g, const std::string& n) {
    auto it = g.actorId.find(n);
    if (it != g.actorId.end()) return it->second;
    int id = (int)g.actorName.size();
    g.actorName.push_back(n);
    g.actorId[n] = id;
    g.adj.push_back({});
    return id;
}
static void movie(Graph& g, const std::string& title, const std::vector<std::string>& names) {
    std::vector<int> ids;
    for (const std::string& n : names) ids.push_back(actor(g, n));
    int m = (int)g.movieTitle.size();
    g.movieTitle.push_back(title);
    for (size_t i = 0; i < ids.size(); i++)
        for (size_t j = i + 1; j < ids.size(); j++)
            if (ids[i] != ids[j]) {
                g.adj[ids[i]].push_back({ids[j], m});
                g.adj[ids[j]].push_back({ids[i], m});
            }
}
// Sample graph. Ids: A0 B1 C2 D3 E4 F5 G6 H7 I8 J9
//   Alpha: A B C   Beta: C D   Gamma: B E   Delta: E D F   Eps: F G
//   Zeta: H H (H has no co-stars)   Alpha (a second movie with the same title): A B   Eta: I J
// Distances from A: A0 B1 C1 D2 E2 F3 G4, H I J unreachable
static Graph sample(const std::string& first = "A") {
    Graph g;
    for (const char* n : {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J"})
        actor(g, std::string(n) == "A" ? first : std::string(n));
    movie(g, "Alpha", {first, "B", "C"});
    movie(g, "Beta", {"C", "D"});
    movie(g, "Gamma", {"B", "E"});
    movie(g, "Delta", {"E", "D", "F"});
    movie(g, "Eps", {"F", "G"});
    movie(g, "Zeta", {"H", "H"});
    movie(g, "Alpha", {first, "B"});
    movie(g, "Eta", {"I", "J"});
    return g;
}
static bool sharesMovie(const Graph& g, int u, int v, int m) {
    for (const Edge& e : g.adj[u]) if (e.actor == v && e.movie == m) return true;
    return false;
}

// ================= queue =================
static void isEmpty_new_queue() {
    Queue q;
    CHECK(isEmpty(q), "a new Queue must be empty");
    Queue r = make_queue(4, 2, {7});
    CHECK(!isEmpty(r), "a Queue holding one value must not be empty");
}
static void enqueue_basic() {
    Queue q = make_queue(4, 0, {});
    enqueue(q, 5); enqueue(q, 6);
    CHECK(holds(q, {5, 6}), "after enqueue 5 and 6, the queue must hold 5, 6 (front first)");
}
static void dequeue_order() {
    Queue q = make_queue(8, 0, {4, 8, 15});
    CHECK(dequeue(q) == 4 && dequeue(q) == 8, "dequeue must return values front first");
    CHECK(holds(q, {15}), "after two dequeues one value must be left");
}
static void clearQueue_basic() {
    Queue q = make_queue(4, 1, {1, 2, 3});
    clearQueue(q);
    CHECK(q.count == 0, "clearQueue must leave count at 0");
    enqueue(q, 42);
    CHECK(holds(q, {42}), "after clearQueue, enqueue 42 must leave exactly 42 in the queue");
}

// ================= building the graph =================
static void addActor_new_and_existing() {
    Graph g;
    CHECK(addActor(g, "Kevin_Bacon") == 0, "the first actor added must get id 0");
    CHECK(addActor(g, "Tom_Hanks") == 1, "the second new actor must get id 1");
    CHECK(addActor(g, "Kevin_Bacon") == 0, "adding an existing actor must return the old id");
    CHECK(g.actorName.size() == 2 && g.adj.size() == 2, "an existing actor must not be added again");
}
static void findActor_present_and_missing() {
    Graph g = sample();
    CHECK(findActor(g, "D") == 3 && findActor(g, "J") == 9, "findActor must return the actor's id");
    CHECK(findActor(g, "Nobody") == -1, "findActor must return -1 for an actor not in the graph");
}
static void addMovie_pairs() {
    Graph g;
    for (const char* n : {"P", "Q", "R"}) actor(g, n);
    addMovie(g, "Trio", {0, 1, 2});
    CHECK(g.movieTitle.size() == 1 && g.movieTitle[0] == "Trio", "addMovie must store the title as movie 0");
    CHECK(g.adj[0].size() == 2 && g.adj[1].size() == 2 && g.adj[2].size() == 2,
          "in a 3-actor movie each actor gets 2 edges");
    CHECK(sharesMovie(g, 0, 1, 0) && sharesMovie(g, 1, 0, 0) && sharesMovie(g, 2, 0, 0),
          "every pair in the cast must be connected in both directions");
}
static void costars_basic() {
    Graph g = sample();
    CHECK(costars(g, 0) == 2, "A has 2 co-stars (B and C): count B once even though they share 2 movies");
    CHECK(costars(g, 1) == 3 && costars(g, 4) == 3, "B and E each have 3 co-stars");
    CHECK(costars(g, 7) == 0, "H is listed twice in one movie but has no co-stars");
}
static void common_basic() {
    Graph g = sample();
    CHECK(common(g, 0, 3) == 1, "A and D share exactly one co-star (C)");
    CHECK(common(g, 1, 3) == 2, "B and D share two co-stars (C and E)");
    CHECK(common(g, 0, 1) == 1, "A and B share C; A and B themselves do not count");
}

// ================= bfs and formatPath =================
static void bfs_distances() {
    Graph g = sample();
    std::vector<int> dist;
    std::vector<Edge> parent;
    bfs(g, 0, -1, -1, dist, parent);
    CHECK(dist.size() == 10 && parent.size() == 10, "dist and parent need one entry per actor");
    int want[10] = {0, 1, 1, 2, 2, 3, 4, -1, -1, -1};
    for (int v = 0; v < 10; v++) CHECK(dist[v] == want[v], "wrong distance in a BFS from A");
}
static void bfs_parents_valid() {
    Graph g = sample();
    std::vector<int> dist;
    std::vector<Edge> parent;
    bfs(g, 6, -1, -1, dist, parent);
    CHECK(parent[6].actor == -1 && parent[7].actor == -1, "the source and unreached actors have parent {-1, -1}");
    for (int v = 0; v < 7; v++) {
        if (v == 6) continue;
        int u = parent[v].actor;
        CHECK(u >= 0 && dist[u] == dist[v] - 1, "parent[v] must be an actor one step closer to the source");
        CHECK(sharesMovie(g, u, v, parent[v].movie), "parent[v].movie must be a movie that v and its parent share");
    }
}
static void formatPath_one_hop() {
    Graph g = sample();
    std::vector<Edge> parent(10, Edge{-1, -1});
    parent[3] = Edge{2, 1};
    CHECK(formatPath(g, 2, 3, parent) == "C -(Beta)- D", "expected: C -(Beta)- D");
}
static void formatPath_multi_hop() {
    Graph g = sample();
    std::vector<Edge> parent(10, Edge{-1, -1});
    parent[1] = Edge{0, 6};
    parent[4] = Edge{1, 2};
    parent[5] = Edge{4, 3};
    CHECK(formatPath(g, 0, 5, parent) == "A -(Alpha)- B -(Gamma)- E -(Delta)- F",
          "expected: A -(Alpha)- B -(Gamma)- E -(Delta)- F");
}

// ================= one BFS, different questions =================
static void within_basic() {
    Graph g = sample();
    CHECK(within(g, 0, 1) == 2, "within(A, 1) is 2 (B, C)");
    CHECK(within(g, 0, 2) == 4, "within(A, 2) is 4 (B, C, D, E)");
    CHECK(within(g, 0, 0) == 0, "within(A, 0) is 0: the actor never counts");
}
static void farthest_basic() {
    Graph g = sample();
    CHECK(farthest(g, 0) == 4 && farthest(g, 6) == 4, "A and G are 4 hops apart");
    CHECK(farthest(g, 3) == 2, "from D, every actor in the group is at most 2 hops away");
    CHECK(farthest(g, 7) == 0, "an actor with no co-stars has farthest 0");
}
static void avoid_basic() {
    Graph g = sample();
    CHECK(avoid(g, 0, 3, 2) == 3, "A to D without C is 3 (A-B-E-D)");
    CHECK(avoid(g, 0, 6, 5) == -1, "every path from A to G goes through F");
    CHECK(avoid(g, 0, 3, 0) == -1 && avoid(g, 0, 3, 3) == -1, "blocking A or B itself gives -1");
}

// ================= new BFS techniques =================
static void count_basic() {
    Graph g = sample();
    CHECK(countShortestPaths(g, 0, 5) == 2, "A to F has 2 shortest paths (A-B-E-F, A-C-D-F)");
    CHECK(countShortestPaths(g, 0, 3) == 1, "A to D has 1 shortest path (A-C-D)");
    CHECK(countShortestPaths(g, 1, 3) == 2, "B to D has 2 shortest paths (B-C-D, B-E-D)");
}
static void meet_basic() {
    Graph g = sample();
    CHECK(meet(g, 0, 5) == 6, "A to F: A, B, C, D, E, F are all on some shortest path");
    CHECK(meet(g, 0, 3) == 3, "A to D: only A, C, D");
    CHECK(meet(g, 0, 7) == 0, "unreachable gives 0");
}

struct UnitTest { const char* name; void (*fn)(); };
static const UnitTest TESTS[] = {
    {"isEmpty/new-queue", isEmpty_new_queue},
    {"enqueue/basic", enqueue_basic},
    {"dequeue/order", dequeue_order},
    {"clearQueue/basic", clearQueue_basic},
    {"addActor/new-and-existing", addActor_new_and_existing},
    {"findActor/present-and-missing", findActor_present_and_missing},
    {"addMovie/pairs", addMovie_pairs},
    {"costars/basic", costars_basic},
    {"common/basic", common_basic},
    {"bfs/distances", bfs_distances},
    {"bfs/parents-valid", bfs_parents_valid},
    {"formatPath/one-hop", formatPath_one_hop},
    {"formatPath/multi-hop", formatPath_multi_hop},
    {"within/basic", within_basic},
    {"farthest/basic", farthest_basic},
    {"avoid/basic", avoid_basic},
    {"countShortestPaths/basic", count_basic},
    {"meet/basic", meet_basic},
};

int main(int argc, char* argv[]) {
    if (argc != 2) { std::cerr << "usage: unit_tests <test-name>\n"; return 2; }
    for (const UnitTest& t : TESTS) {
        if (std::string(argv[1]) == t.name) {
            t.fn();
            std::cout << (g_fail.empty() ? "PASS" : "FAIL: " + g_fail) << std::endl;
            return 0;
        }
    }
    std::cout << "FAIL: no such test" << std::endl;
    return 0;
}
