# CSE 101 Programming Assignment: Six Degrees of Kevin Bacon

The full assignment description is in the handout PDF. This page explains how to use this repository.

## Setup

### 1. Make your own private copy

You cannot push to the course repository, so first make a copy that belongs to you.

1. Sign in to GitHub and open https://github.com/CSE-101-UCSC/Homework-3.
2. Click the green **Use this template** button, then **Create a new repository**.
   **Do not click Fork.** A fork of this repository is always public, and making your solution public is an academic integrity violation.
3. On the **Create a new repository** page:
   - **Owner:** your own GitHub account.
   - **Repository name:** anything you like, for example `cse101-homework-3`.
   - **Visibility:** choose **Private**. This is required.
   - Leave **Include all branches** unchecked.
4. Click **Create repository**. Check that your new repository shows the label **Private** next to its name.

**Already cloned the course repository instead?** Your clone is still connected to the course repository, so you cannot push your work. Create an empty **private** repository on GitHub (no README, no .gitignore), then run these commands inside your clone, using your new repository's URL:

```
git remote set-url origin https://github.com/<your-username>/<your-repository>.git
git push -u origin main
```

### 2. Open it in a Codespace

On **your** repository's page (not the course repository), click **Code → Codespaces → Create codespace on main**. The first start takes a minute or two. If VS Code asks whether you trust the authors of the files in this folder, click **Trust Folder & Continue**; otherwise the terminal will not open. The Codespace runs Linux like Gradescope.

Your free GitHub account includes monthly Codespaces hours, which is plenty for this assignment. A Codespace stops by itself after 30 minutes of inactivity; to reopen it, go to **Code → Codespaces** on your repository and click its name.

You can also work on your own Mac or Windows computer instead. See [Working on your own computer](#working-on-your-own-computer).

### 3. Build the starter code

In the Codespace terminal, run `make`. You should see `Rule check passed.` followed by a successful build. Then run `./run_tests.sh`. Every test fails until you write your code; that is expected.

## What is in this repository

| File or folder | What it is | Can you edit it? |
|---|---|---|
| `main.cpp` | `main()`: reads `cleaned_movielist.txt`, reads the input file, writes the output file. `answerQuery`, which calls your functions for each query, is provided; the reading and writing start as `TODO`s. | **Yes** (not `answerQuery`) |
| `queue.cpp` | Your queue: the four functions in `queue.h`, stored in a circular buffer. Every function starts as a `TODO`. | **Yes** |
| `graph.cpp` | Your graph and BFS functions: the sixteen functions in `graph.h`. Every function starts as a `TODO`. | **Yes** |
| `citations.md` | Your list of outside resources (works cited) | **Yes** |
| `README.md` | These instructions | No |
| `queue.h` | The `Queue` type and the queue functions you must implement | No |
| `graph.h` | The graph types and the graph functions you must implement | No |
| `cleaned_movielist.txt` | The data: 131,071 movies from IMDb, one per line | No |
| `small/cleaned_movielist.txt` | The 13-movie data file from the handout's example | No |
| `Makefile` | Checks the rules and builds `./sixdegrees` | No |
| `run_tests.sh` | Runs the visible tests | No |
| `scripts/` | The rule checker used by `make`, the function tests, and the path checker | No |
| `tests/` | One folder per visible test | No |

Gradescope uses the original copies of every file you cannot edit. If you change one by accident, restore it with `git checkout -- <file>`.

## Building

```
make          # check the rules, then build ./sixdegrees
make clean    # remove the program and saved test output
```

`make` refuses to build if any rule is broken. It tells you which rule and how to fix it.

## Running your program

Your program reads `cleaned_movielist.txt` from the folder you run it in, so run it here for the full data, or inside `small/` for the 13-movie file:

```
./sixdegrees tests/25_path_sesh_more/input.txt my_output.txt
cd small && ../sixdegrees ../tests/23_example/input.txt ../my_output.txt
```

To try your own queries, write them in a file (one per line) and run `./sixdegrees my_queries.txt my_output.txt`.

## Testing

```
./run_tests.sh            # run every visible test
./run_tests.sh count      # run only tests with "count" in the name
./run_tests.sh 12         # run only test 12
./run_tests.sh --list     # list every test and what it checks
make test                 # same as ./run_tests.sh
```

There are two kinds of tests. **Function tests** (01 to 18) call one `queue.h` or `graph.h` function directly on a small graph built by the test, so they work even before `main.cpp` is finished. **Query tests** (19 to 42) run your whole program on an input file and compare the output file it writes.

For each failing test, the script shows the command, what the test checks, and a comparison:

```
line 2: Brad_Pitt Tom_Cruise
- Brad_Pitt -(Troy:_In_the_Thick_of_Battle)- Simon_Crane -(A_World_on_the_'Edge_of_Tomorrow')- Tom_Cruise
+ Brad_Pitt -(Pros_and_Cons:_Inside_Ocean's_Outfit)- Steven_Soderbergh -(...)- ...
  (your path has 311 hops; the shortest has 2)
```

A path answer is correct if it is **any** shortest path: it must start and end with the right actors, have as many hops as the expected path, and each pair of neighbors must really appear together in the movie between them. So your path may differ from the one in `expected.txt` and still pass. Every other answer must match exactly.

When every test passes, it prints `All 42 tests passed!`. Your program's output file for every query test is saved in `test_output/`, and what it printed to `std::cerr` is saved next to it in a `.stderr.txt` file. Every test must finish within 10 seconds.

These are the visible tests only. Gradescope also runs hidden tests, so passing everything here does not guarantee full credit. Write extra input files of your own and check the results by hand.

## Rules enforced by `make`

- The only source files are `main.cpp`, `graph.cpp`, and `queue.cpp`. No other `.cpp` or `.h` files.
- `graph.h` and `queue.h` must not be changed. Put helper functions in your `.cpp` files as `static` functions; do not declare them in a header.
- `main()` is defined in `main.cpp`, every function in `graph.h` is defined in `graph.cpp`, and every function in `queue.h` is defined in `queue.cpp`, each with the exact same name and parameters.
- Your files may include only `<string>`, `<iostream>`, `<fstream>`, `<sstream>`, `<vector>`, `<unordered_map>`, `<cstdlib>`, `"graph.h"`, and `"queue.h"`.
- No `std::queue`, `std::deque`, or `std::priority_queue`: use your own `Queue` from `queue.h`.
- Code is compiled with `g++ -std=c++17 -O2 -Wall -Wextra -pedantic-errors`.

## Saving your work

Work in a Codespace or on your computer is **not on GitHub until you commit and push it**, and Gradescope grades what is on GitHub. Save often:

```
git add main.cpp graph.cpp queue.cpp citations.md
git commit -m "Describe what you changed"
git push
```

In a Codespace you can also use the **Source Control** panel on the left: type a message, click **Commit**, then **Sync Changes**.

## Working on your own computer

A Codespace needs no setup and runs Linux like Gradescope, so it is the safest choice. If you would rather work on your own computer, set it up once as described below, then clone **your** private repository and use `make` and `./run_tests.sh` exactly as described above. You also need Python 3, which `run_tests.sh` uses to check path answers.

To clone a private repository you must sign in to GitHub. The easiest way is the GitHub CLI: install it (see below), run `gh auth login` and follow the prompts, then run `gh repo clone <your-username>/<your-repository>`.

**macOS.** Open Terminal and run `xcode-select --install` to install Apple's compiler and `make`. Install the GitHub CLI from https://cli.github.com. On a Mac, `g++` is Apple's clang compiler rather than GNU g++. Code that builds on a Mac almost always builds on Gradescope, but Gradescope's result is the one that counts: if it reports a build error that your Mac did not, fix it and submit again.

**Windows.** Use WSL (Windows Subsystem for Linux), which gives you the same Linux tools as Gradescope:

1. Open PowerShell as administrator, run `wsl --install`, and restart your computer.
2. Open **Ubuntu** from the Start menu and run `sudo apt update && sudo apt install -y g++ make git gh`.
3. Clone your repository inside Ubuntu's home folder (run `cd ~` first), not in a Windows folder under `/mnt/c`.

Do your work in the Ubuntu terminal. VS Code can open the folder with the **WSL** extension.

## Submitting

1. Fill in `citations.md` with every outside resource you used, or **None.**
2. Run `make clean`, then commit and push your work (see [Saving your work](#saving-your-work)). Open your repository on GitHub and check that your latest changes are there.
3. On Gradescope, open the assignment and submit with the **GitHub** option. The first time, Gradescope asks you to connect your GitHub account; allow it. Then choose your repository and the `main` branch.
4. Gradescope grades the code at the moment you submit. If you push changes later, submit again.

If your repository does not appear in Gradescope's list, make sure you are connected with the same GitHub account that owns the repository.
