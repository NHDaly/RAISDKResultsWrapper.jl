# RAISDKResultsWrapper

This is a playground for exploring the ideas in the associated design doc: https://docs.google.com/document/d/184IRnBmIk36UM4elF-L6fZ0ZB4IeP0mWWT6o1fbq78I/edit#.

The main interfaces are:
- the RelationIterator (currently produced from an RAI.exec result via `output()`)
- `tuples()`
- `relations()`

## Examples
```julia
julia> r = RAI.exec(ctx, "nhd-test-1", "nhd-s", """
           :a, (1; 2; (3, "hi"));
           :b, "hi", :c, (range[2, 100, 1]);
           :x, true;
           :y, (10; 100), 20
           """)
JSON3.Object{Vector{UInt8}, Vector{UInt64}} with 6 entries:
  :output      => JSON3.Object[{…
  :problems    => Union{}[]
  :actions     => JSON3.Object[{…
  :debug_level => 0
  :aborted     => false
  :type        => "TransactionResult"

julia> iter = output(r)
RelationIterator with 105 tuples in 5 physical relations:
":output" =>
        ":a" =>
           1 =>
           2 =>
           3 =>
             "hi" =>
        ":b" =>
           "hi" =>
              ":c" =>
                 2 =>
                 3 =>
                 4 =>
                 5 =>
                 6 =>
                 ⋮
        ":x" =>
        ":y" =>
           10 =>
             20 =>
               5 =>
             19 =>
           100 =>
             20 =>
             19 =>
               5 =>

julia> iter[":output"][":y"]
RelationIterator with 2 tuples in 1 physical relations:
10 =>
  20 =>
    5 =>
  19 =>
100 =>
  20 =>
  19 =>
    5 =>

julia> iter[":output"][":y"][10]  # This should only show `(20, 5)`, but it's still buggy
RelationIterator with 2 tuples in 1 physical relations:
20 =>
  5 =>
19 =>

julia> tuples(iter[":output"][":a"])
TuplesIterator with 3 tuples:
  (1,)
  (2,)
  (3, "hi")

julia> collect(tuples(iter[":output"][":a"]))[3]
(3, "hi")

julia> relations(iter[":output"][":a"])
2-element Vector{PhysicalRelation}:
 PhysicalRelation([":output", ":a", "Int64"], TuplesIterator(Tuple[(:output, :a, 1), (:output, :a, 2)]))
 PhysicalRelation([":output", ":a", "Int64", "String"], TuplesIterator(Tuple[(:output, :a, 3, "hi")]))

julia> tuples(relations(iter[":output"][":a"]))
TuplesIterator with 3 tuples:
  (:output, :a, 1)
  (:output, :a, 2)
  (:output, :a, 3, "hi")
```
