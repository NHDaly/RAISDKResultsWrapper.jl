function output(transaction_result)
    json = transaction_result.output
    return ResultsCursor(TrieWalker(relations(json)), json)
end

struct ResultsCursor  # TODO: Name?
    iterator::TrieWalker
    _json_outputs::JSON3.Array
end

function Base.show(io::IO, ::MIME"text/plain", cursor::ResultsCursor)
    num_rels = length(cursor.iterator.relations)
    print(io, "$ResultsCursor with <TODO> tuples in $(num_rels) physical relations:")
    _show_trie(io, cursor)
end


Base.keys(cursor::ResultsCursor) = keys(cursor.iterator)
Base.getindex(cursor::ResultsCursor, element) =
    ResultsCursor(cursor.iterator[element], cursor._json_outputs)
function Base.getindex(cursor::ResultsCursor, elements...)
    for element in elements
        cursor = getindex(cursor, element)
    end
    return cursor
end



function _show_trie(io, cursor::ResultsCursor)
    __show_trie(io, cursor)
end
function __show_trie(io, cursor::ResultsCursor; indent=0, num_lines = 10)
    for key in keys(cursor)
        num_lines -= 1
        if num_lines < 0
            print("\n" * " "^indent, "⋮")
            return
        end
        print("\n" * " "^indent, repr(key), " => ")
        __show_trie(io, cursor[key];
            indent = indent + length(key)+1,
            num_lines = num_lines)
    end
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
