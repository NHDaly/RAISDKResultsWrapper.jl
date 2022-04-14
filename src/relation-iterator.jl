function output(transaction_result)
    json = transaction_result.output
    return RelationIterator(TrieWalker(relations(json)))
end

struct RelationIterator  # TODO: Name?
    iterator::TrieWalker
end

function Base.show(io::IO, ::MIME"text/plain", cursor::RelationIterator)
    num_rels = length(cursor.iterator.relations)
    tups = tuples(cursor)
    print(io, "$RelationIterator with $(length(tups)) tuples in $(num_rels) physical relations:")
    _show_trie(io, cursor)
end


Base.keytype(_::RelationIterator) = Any
Base.keys(cursor::RelationIterator) = keys(cursor.iterator)
Base.getindex(cursor::RelationIterator, element) = RelationIterator(cursor.iterator[element])
function Base.getindex(cursor::RelationIterator, elements...)
    for element in elements
        cursor = getindex(cursor, element)
    end
    return cursor
end



function _show_trie(io, cursor::RelationIterator)
    __show_trie(io, cursor)
end
function __show_trie(io, cursor::RelationIterator; indent=0, num_lines = 10)
    for key in keys(cursor)
        num_lines -= 1
        if num_lines < 0
            print("\n" * " "^indent, "⋮")
            return
        end
        print("\n" * " "^indent, repr(key))
        subcursor = cursor[key]
        #if !isempty(tuples(subcursor))
            print(io, " => ")
            __show_trie(io, subcursor;
                indent = indent + length(key)+1,
                num_lines = num_lines)
        #end
    end
end




function tuples(cursor::RelationIterator)
    len = sum((_num_tuples(r) for r in relations(cursor)), init=0)
    tuples = (
        row_getter(i)[(length(cursor.iterator.prefix)+1):end]
        for r in sort(relations(cursor), by=r->r.relpath)
        for row_getter in (RAI._make_getrow(r.relpath, r.columns),)
        for i in 1:_num_tuples(r)
    )
    return TuplesIterator(len, tuples)
end


function relations(cursor::RelationIterator)
    return PhysicalRelation[
        r_iter.relation
        for r_iter in cursor.iterator.relations
    ]
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
