module RAISDKResultsWrapper

import RAI
import JSON3
using DataStructures: OrderedSet

export output, tuples, relations
export RelationIterator, TuplesIterator, PhysicalRelation

include("tuples.jl")
include("physical-relations.jl")
include("trie-iterator.jl")
include("cursor.jl")

end
