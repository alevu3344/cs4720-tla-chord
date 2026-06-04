---------------------------- MODULE ChordStatic ----------------------------
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS 
    M,      \* Number of bits for the ID space (e.g., 3)
    Nodes   \* The set of active nodes in the static ring (e.g., {0, 1, 3})

VARIABLES 
    succ,   \* succ[n] is the immediate successor of node n
    finger, \* finger[n][i] is the i-th finger of node n
    queries \* A set of ongoing lookups

\* The set of all possible IDs in the ring: 0 .. 2^M - 1
Ring == 0 .. (2^M - 1)

\* Helper for modular addition
AddMod(a, b) == (a + b) % (2^M)

\* Open interval (a, b) on a ring
InOpenInterval(x, a, b) ==
    IF a < b THEN (x > a) /\ (x < b)
    ELSE (x > a) \/ (x < b)

\* Right-half closed interval (a, b] on a ring
InRightHalfClosed(x, a, b) ==
    IF a < b THEN (x > a) /\ (x <= b)
    ELSE (x > a) \/ (x <= b)

\* Helper: Find true successor of Key 'n' among the active 'Nodes'
TrueSucc(n) == 
    \* If the key falls exactly on an existing node, that node is the successor
    IF n \in Nodes THEN 
        n
    \* Otherwise, find the first node 's' that follows 'n'
    ELSE 
        CHOOSE s \in Nodes : 
            \A m \in Nodes \ {s} : 
                InRightHalfClosed(s, n, m)

Init ==
    \* Initialize successors
    /\ succ = [n \in Nodes |-> TrueSucc(AddMod(n, 1))]

    \* Initialize finger tables
    /\ finger = [n \in Nodes |-> 
                    [i \in 1..M |-> TrueSucc(AddMod(n, 2^(i-1)))]
                ]
                
    \* No queries at start
    /\ queries = {}

\* Find all finger indices that fall strictly between 'n' and 'id'
ValidFingers(n, id) == 
    { i \in 1..M : InOpenInterval(finger[n][i], n, id) }

\* Return the finger node with the highest index, or 'n' if none exist
ClosestPrecedingFinger(n, id) ==
    IF ValidFingers(n, id) /= {} THEN
        LET max_i == CHOOSE i \in ValidFingers(n, id) : 
                        \A j \in ValidFingers(n, id) : i >= j
        IN finger[n][max_i]
    ELSE 
        n

\* We use "None" represent an unresolved query.

\* Action 1: Node 'n' wants to look up key 'k'. We add a new query record to the set.
StartQuery(n, k) ==
    \* Prevent infinite queries from flooding the state space during model checking
    \* by only allowing one active query per (node, key) pair.
    /\ \neg (\E q \in queries : q.origin = n /\ q.target = k)
    /\ queries' = queries \cup {[origin |-> n, target |-> k, curr |-> n, result |-> "None"]}
    \* State of the ring doesn't change
    /\ UNCHANGED <<succ, finger>>

\* Action 2: Process a query that hasn't been resolved yet
AdvanceQuery(q) ==
    \* If the target is between the current node and its successor...
    IF InRightHalfClosed(q.target, q.curr, succ[q.curr]) THEN
        LET resolved_q == [q EXCEPT !.result = succ[q.curr]] IN
        queries' = (queries \ {q}) \cup {resolved_q}
    ELSE
        LET next_node == ClosestPrecedingFinger(q.curr, q.target) IN
        /\ next_node /= q.curr 
        /\ LET forwarded_q == [q EXCEPT !.curr = next_node] IN
           queries' = (queries \ {q}) \cup {forwarded_q}
    /\ UNCHANGED <<succ, finger>>

Next == 
    \/ (\E n \in Nodes, k \in Ring : StartQuery(n, k))
    \/ (\E q \in queries : q.result = "None" /\ AdvanceQuery(q))

Spec == Init /\ [][Next]_<<succ, finger, queries>>
