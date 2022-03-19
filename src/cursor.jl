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
