module RAISDKResultsWrapper

import RAI
import JSON3


export output, tuples, relations
export ResultsCursor, TuplesIterator, PhysicalRelation

include("tuples.jl")
include("physical-relations.jl")
include("trie-iterator.jl")
include("cursor.jl")

end
