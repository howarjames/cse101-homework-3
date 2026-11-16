"""Compares your output file with the expected one, the way Gradescope does.

    python3 tests/check_paths.py <data_file> <input_file> <expected_file> <your_file>

Number answers must match exactly. A path answer (a line of the input with two actor
names and no keyword) is correct if it is ANY shortest path: it starts and ends with the
right actors, has as many hops as the expected path, and each pair of neighbors really
appears together in the movie between them. Prints nothing if every line is correct.
"""
import sys

KEYWORDS = {'COSTARS', 'COMMON', 'WITHIN', 'FARTHEST', 'AVOID', 'COUNT', 'MEET'}


def read_lines(path):
    with open(path, encoding='utf-8', errors='replace') as f:
        text = f.read().replace('\r\n', '\n')
    return text[:-1].split('\n') if text.endswith('\n') else (text.split('\n') if text else [])


def main():
    data, inp, expected, yours = sys.argv[1:5]
    queries = [l for l in read_lines(inp) if l.split()]
    want = read_lines(expected)
    got = read_lines(yours)
    with open(yours, encoding='utf-8', errors='replace') as f:
        raw = f.read()
    if raw and not raw.endswith('\n'):
        print('        the last line of your output file does not end with a newline')
        return
    movies = None   # (actor, actor) -> set of titles, loaded only if needed
    shown = 0
    for k in range(max(len(want), len(got))):
        q = queries[k] if k < len(queries) else '(no query)'
        x = want[k] if k < len(want) else '(no line)'
        y = got[k] if k < len(got) else '(no line)'
        if x == y:
            continue
        words = q.split()
        problem = None
        if len(words) == 2 and words[0] not in KEYWORDS and x != 'Not present' and y != '(no line)':
            if movies is None:
                movies = {}
                with open(data, encoding='utf-8') as f:
                    for line in f:
                        w = line.split()
                        cast = list(dict.fromkeys(w[1:]))
                        for i in range(len(cast)):
                            for j in range(i + 1, len(cast)):
                                movies.setdefault(tuple(sorted((cast[i], cast[j]))), set()).add(w[0])
            parts = y.replace('-(', ' ').replace(')-', ' ').split()
            hops = x.count(' -(')
            if y == 'Not present':
                problem = 'there is a path, but your output says Not present'
            elif len(parts) % 2 == 0:
                problem = 'not in the form ACTOR -(MOVIE)- ACTOR ...'
            elif parts[0] != words[0] or parts[-1] != words[1]:
                problem = 'the path must start with %s and end with %s' % (words[0], words[1])
            elif (len(parts) - 1) // 2 != hops:
                problem = 'your path has %d hops; the shortest has %d' % ((len(parts) - 1) // 2, hops)
            else:
                for i in range(0, len(parts) - 2, 2):
                    a, m, b = parts[i], parts[i + 1], parts[i + 2]
                    if m not in movies.get(tuple(sorted((a, b))), ()):
                        problem = '%s and %s are not both in %s' % (a, b, m)
                        break
            if problem is None:
                continue    # a different, equally short, valid path: correct
        print('        line %d: %s' % (k + 1, q))
        print('        - %s' % x[:300])
        print('        + %s' % y[:300])
        if problem:
            print('          (%s)' % problem)
        shown += 1
        if shown == 3:
            break


if __name__ == '__main__':
    main()
