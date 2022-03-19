module RAISDKResultsWrapper

import RAI
import JSON3


export output, tuples

function output(transaction_result)
    return ResultsCursor(transaction_result.output)
end

struct ResultsCursor  # TODO: Name?
    json_outputs::JSON3.Array
end

#function Base.show(io::IO, ::MIME"text/plain", cursor::ResultsCursor)
#    #len =
#    print(io, "$ResultsCursor with ")
#end

function tuples(cursor::ResultsCursor)
    len = sum(_num_tuples(r) for r in relations(cursor))
    tuples = (
        row_getter(i)
        for r in sort(relations(cursor), by=r->r.relpath)
        for row_getter in (RAI._make_getrow(r.relpath, r.columns),)
        for i in 1:_num_tuples(r)
    )
    return TuplesIterator(len, tuples)
end

function _constants_positions(relpath)
    return ((i,v) for (i,v) in enumerate(relpath) if startswith(v,':'))
end

struct TuplesIterator{G}
    length::Int
    generator::G
end
TuplesIterator(itr) = TuplesIterator(length(itr), itr)

# iteration interface
Base.iterate(t::TuplesIterator, args...) = iterate(t.generator, args...)
Base.length(t::TuplesIterator) = t.length
Base.eltype(::Type{<:TuplesIterator}) = Tuple

function Base.show(io::IO, tuples::TuplesIterator)
    Base.print(io, "$TuplesIterator(")
    Base.show(io, collect(Tuple, tuples.generator))
    Base.print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", tuples::TuplesIterator)
    print(io, "$TuplesIterator with $(tuples.length) tuples:")
    # isempty(iter) && get(io, :compact, false) && return show(io, iter)
    # summary(io, iter)
    # isempty(iter) && return
    # print(io, ". ", isa(iter,KeySet) ? "Keys" : "Values", ":")
    _show_list(io, tuples)
end

function _show_list(io::IO, iter)
    limit = get(io, :limit, false)::Bool
    if limit
        sz = displaysize(io)
        rows, cols = sz[1] - 3, sz[2]
        rows < 2 && (print(io, " …"); return)
        cols < 4 && (cols = 4)
        cols -= 2 # For prefix "  "
        rows -= 1 # For summary
    else
        rows = cols = typemax(Int)
    end

    for (i, v) in enumerate(iter)
        print(io, "\n  ")
        i == rows < length(iter) && (print(io, "⋮"); break)

        if limit
            str = sprint(show, v, context=io, sizehint=0)
            str = Base._truncate_at_width_or_chars(str, cols, "\r\n")
            print(io, str)
        else
            show(io, v)
        end
    end
end



function relations(cursor::ResultsCursor)
    return PhysicalRelation[
        PhysicalRelation(_relpath_from_rel_key(relation.rel_key), relation.columns)
        for relation in cursor.json_outputs
    ]
end
function _relpath_str(rel_key::JSON3.Object)
    name_and_keys = reduce(joinpath, rel_key.keys, init=":$(rel_key.name)")
    name_keys_values = reduce(joinpath, rel_key.values, init=name_and_keys)
    return name_keys_values
end
function _relpath_from_rel_key(rel_key::JSON3.Object)
    return String[":$(rel_key.name)", rel_key.keys..., rel_key.values...]
end

struct PhysicalRelation
    relpath::Vector{String}
    columns::JSON3.Array
end

_num_tuples(r::PhysicalRelation) = max(length(r.columns[1]), 1)

struct RelationTuples
    columns::JSON3.Array
end

function Base.show(io::IO, tuples::RelationTuples)
    print(io, "$RelationTuples([])")
end



end
