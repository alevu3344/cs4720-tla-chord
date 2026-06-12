---------------------------- MODULE ChordDynamic ----------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS
    M,              \* Number of bits in the identifier space.
    InitialNodes,   \* Nodes present in the initially stable Chord ring.
    JoinNodes       \* Nodes that may join nondeterministically.

VARIABLES
    active,         \* Nodes currently in the Chord ring.
    succ,           \* succ[n] is n's current immediate successor pointer.
    pred,           \* pred[n] is n's current predecessor pointer, or Nil.
    finger,         \* finger[n][i] is n's current i-th finger entry.
    nextFinger,     \* next finger index repaired by round-robin fix_fingers.
    notifyMsgs      \* In-flight asynchronous notify messages.

\* Identifier space 0 .. 2^M - 1.
Ring == 0 .. (2^M - 1)

\* Sentinel used for an unknown predecessor. It is outside Ring.
Nil == 2^M

AllNodes == InitialNodes \cup JoinNodes

ASSUME /\ M \in Nat \ {0}
       /\ InitialNodes \subseteq Ring
       /\ JoinNodes \subseteq Ring
       /\ InitialNodes # {}
       /\ InitialNodes \cap JoinNodes = {}

StateVars == <<active, succ, pred, finger, nextFinger, notifyMsgs>>

NotifyRecord == [from : AllNodes, to : AllNodes]

TypeOK ==
    /\ active \subseteq AllNodes
    /\ active # {}
    /\ succ \in [active -> active]
    /\ pred \in [active -> active \cup {Nil}]
    /\ finger \in [active -> [1..M -> active]]
    /\ nextFinger \in [active -> 1..M]
    /\ notifyMsgs \subseteq NotifyRecord
    /\ \A msg \in notifyMsgs : msg.from \in active /\ msg.to \in active

Extend(f, key, value) ==
    [x \in DOMAIN f \cup {key} |-> IF x = key THEN value ELSE f[x]]

AddMod(a, b) == (a + b) % (2^M)

\* Open interval (a, b) on a modular identifier ring.
InOpenInterval(x, a, b) ==
    IF a < b THEN (x > a) /\ (x < b)
    ELSE (x > a) \/ (x < b)

\* Right-half closed interval (a, b] on a modular identifier ring.
InRightHalfClosed(x, a, b) ==
    IF a < b THEN (x > a) /\ (x <= b)
    ELSE (x > a) \/ (x <= b)

\* Mathematical successor of key k in a concrete node set.
TrueSuccIn(nodes, k) ==
    IF k \in nodes THEN
        k
    ELSE
        CHOOSE s \in nodes :
            \A n \in nodes \ {s} :
                InRightHalfClosed(s, k, n)

\* Mathematical predecessor of node n in a concrete node set.
TruePredIn(nodes, n) ==
    CHOOSE p \in nodes : TrueSuccIn(nodes, AddMod(p, 1)) = n

RECURSIVE FollowSucc(_, _)

\* Follow the current successor pointers for a bounded number of hops.
FollowSucc(n, hops) ==
    IF hops = 0 THEN n ELSE FollowSucc(succ[n], hops - 1)

Init ==
    /\ active = InitialNodes
    /\ succ = [n \in InitialNodes |-> TrueSuccIn(InitialNodes, AddMod(n, 1))]
    /\ pred = [n \in InitialNodes |-> TruePredIn(InitialNodes, n)]
    /\ finger = [n \in InitialNodes |->
                    [i \in 1..M |-> TrueSuccIn(InitialNodes, AddMod(n, 2^(i-1)))]]
    \* Every node starts the round-robin repair cycle at finger index 1.
    /\ nextFinger = [n \in InitialNodes |-> 1]
    /\ notifyMsgs = {}

\* Initialize local state for a joining node.
\* The paper asks a known contact node to route find_successor(n). This model
\* abstracts that RPC to the mathematical successor in the current active ring;
\* the static model covers lookup-hop behavior separately.
Join(n) ==
    LET s == TrueSuccIn(active, n) IN
    /\ n \in JoinNodes \ active
    /\ active' = active \cup {n}
    /\ succ' = Extend(succ, n, s)
    /\ pred' = Extend(pred, n, Nil)
    \* Initial fingers are usable active-node pointers but may be stale.
    /\ finger' = Extend(finger, n, [i \in 1..M |-> s])
    \* The joining node also starts repairing from finger index 1.
    /\ nextFinger' = Extend(nextFinger, n, 1)
    /\ notifyMsgs' = notifyMsgs

\* Consult successor.predecessor and send notify.
Stabilize(n) ==
    /\ n \in active
    /\ LET x == pred[succ[n]] IN
       LET newSucc == IF x # Nil /\ InOpenInterval(x, n, succ[n])
                      THEN x
                      ELSE succ[n] IN
       /\ succ' = [succ EXCEPT ![n] = newSucc]
       /\ notifyMsgs' = notifyMsgs \cup {[from |-> n, to |-> newSucc]}
    /\ UNCHANGED <<active, pred, finger, nextFinger>>

\* Delivered nondeterministically from notifyMsgs.
DeliverNotify(msg) ==
    /\ msg \in notifyMsgs
    /\ LET n == msg.to IN
       LET candidate == msg.from IN
       /\ pred' = [pred EXCEPT ![n] =
              IF pred[n] = Nil \/ InOpenInterval(candidate, pred[n], n)
              THEN candidate
              ELSE pred[n]]
    /\ notifyMsgs' = notifyMsgs \ {msg}
    /\ UNCHANGED <<active, succ, finger, nextFinger>>

\* Refresh one slot, then advance cyclically through 1..M.
FixFingers(n) ==
    /\ n \in active
    /\ LET i == nextFinger[n] IN
       LET start == AddMod(n, 2^(i-1)) IN
       /\ finger' = [finger EXCEPT ![n][i] = TrueSuccIn(active, start)]
       /\ nextFinger' = [nextFinger EXCEPT ![n] =
              IF i = M THEN 1 ELSE i + 1]
    /\ UNCHANGED <<active, succ, pred, notifyMsgs>>

Next ==
    \/ \E n \in JoinNodes : Join(n)
    \/ \E n \in AllNodes : Stabilize(n)
    \/ \E msg \in NotifyRecord : DeliverNotify(msg)
    \/ \E n \in AllNodes : FixFingers(n)

\* A join must not create a successor cycle disconnected from the initial ring.
SuccessorCoreReachable ==
    \A n \in active :
        \E hops \in 0..Cardinality(active) :
            FollowSucc(n, hops) \in InitialNodes

\* Stable-state predicates used by verifier configs and liveness checks.
SuccessorsStable ==
    \A n \in active : succ[n] = TrueSuccIn(active, AddMod(n, 1))

PredecessorsStable ==
    \A n \in active : pred[n] = TruePredIn(active, n)

FingersStable ==
    \A n \in active :
        \A i \in 1..M : finger[n][i] = TrueSuccIn(active, AddMod(n, 2^(i-1)))

StableRing == SuccessorsStable /\ PredecessorsStable /\ FingersStable

AllJoinsDone == JoinNodes \subseteq active

\* If all configured joins occur, fair stabilization and finger repair converge.
EventuallyStableAfterJoins == AllJoinsDone ~> StableRing

Spec ==
    /\ Init
    /\ [][Next]_StateVars
    /\ \A n \in JoinNodes : WF_StateVars(Join(n))
    /\ \A n \in AllNodes : WF_StateVars(Stabilize(n))
    /\ \A n \in AllNodes : WF_StateVars(FixFingers(n))
    /\ \A msg \in NotifyRecord : WF_StateVars(DeliverNotify(msg))
=============================================================================
