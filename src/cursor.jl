function output(transaction_result)
    json = transaction_result.output
    return ResultsCursor(TrieWalker(relations(json)), json)
end

struct ResultsCursor  # TODO: Name?
    iterator::TrieWalker
    _json_outputs::JSON3.Array
end

# TODO: for now, we just show tuples(), but the goal is to show a Trie here!
function Base.show(io::IO, ::MIME"text/plain", cursor::ResultsCursor)
    tups = tuples(cursor)
    rels = relations(cursor)
    print(io, "$ResultsCursor with $(length(tups)) tuples in $(length(rels)) physical relations:")
    _show_list(io, tups)
end


function tuples(cursor::ResultsCursor)
    len = sum((_num_tuples(r) for r in relations(cursor)), init=0)
    tuples = (
        row_getter(i)
        for r in sort(relations(cursor), by=r->r.relpath)
        for row_getter in (RAI._make_getrow(r.relpath, r.columns),)
        for i in 1:_num_tuples(r)
    )
    return TuplesIterator(len, tuples)
end


function relations(cursor::ResultsCursor)
    return relations(cursor._json_outputs)
end

function relations(outputs::JSON3.Array)
    return PhysicalRelation[
        PhysicalRelation(_relpath_from_rel_key(relation.rel_key), relation.columns)
        for relation in outputs
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
