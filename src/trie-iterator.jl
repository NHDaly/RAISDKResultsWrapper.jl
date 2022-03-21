
@enum ColumnType SPECIALIZED VALUES
struct ColumnOrSpecialized
    type::ColumnType
    val::Union{Any,Vector}
end
function _unspecialized_columns(relation::PhysicalRelation)
    col = 0
    ColumnOrSpecialized[
        if startswith(v, ':')
            ColumnOrSpecialized(SPECIALIZED, v)
        else
            col += 1
            ColumnOrSpecialized(VALUES, relation.columns[col])
        end
        for v in relation.relpath
    ]
end

struct PhysicalRelationIterator
    relpath::Vector{String}
    maybe_columns::Vector{ColumnOrSpecialized}
    relation::PhysicalRelation

    row_idx::Int # Current row offset into the relation
end

function PhysicalRelationIterator(r::PhysicalRelation)
    return PhysicalRelationIterator(r.relpath, _unspecialized_columns(r), r, 1)
end
function seek_to(iter::PhysicalRelationIterator, i::Int)
    return PhysicalRelationIterator(iter.relpath, iter.maybe_columns, iter.relation, i)
end

struct TrieWalker
    relations::Vector{PhysicalRelationIterator}
    # relations::Vector{PhysicalRelation}
    # element_getters::Vector{Any}
    # slots::Vector{Vector{Int}}
    # column_getters::Vector{Vector{Int}}
    # TODO: Should this be a dynamically sized collection instead, like a vector? I think probably.
    prefix::Tuple
end

function TrieWalker(relations::Vector{PhysicalRelation})
    return TrieWalker([PhysicalRelationIterator(r) for r in relations], ())
end

function Base.keys(t::TrieWalker)
    e = length(t.prefix) + 1

    keyset = sizehint!(OrderedSet{Any}(), length(t.relations))
    for iter in t.relations
        if e <= length(iter.maybe_columns)
            maybe_col = iter.maybe_columns[e]
            if maybe_col.type == SPECIALIZED
                push!(keyset, maybe_col.val)
            else
                col = maybe_col.val::AbstractVector
                sizehint!(keyset, length(keyset) + length(col))
                for v in col
                    push!(keyset, v)
                end
            end
        end
    end
    return keyset
end

function Base.getindex(t::TrieWalker, v)
    e = length(t.prefix) + 1

    new_iters = sizehint!(empty(t.relations), length(t.relations))
    for iter in t.relations
        new_idx = _seek_match(iter, iter.row_idx, e, v)
        if new_idx !== NotFound()
            iter = seek_to(iter, new_idx)
            push!(new_iters, iter)
        else
            # drop the iterator
        end
    end

    TrieWalker(new_iters, (t.prefix..., v))
end

struct NotFound end

function _seek_match(iter, start_idx::Int, elt_idx::Int, v)
    if elt_idx > length(iter.maybe_columns)
        return NotFound()
    end
    maybe_col = iter.maybe_columns[elt_idx]
    if maybe_col.type == SPECIALIZED
        return maybe_col.val == v ? start_idx : NotFound()
    end
    # Otherwise, it's a normal column
    col = maybe_col.val::AbstractVector

    # Do a binary search from start_idx to end until you find `v` in column elt_idx
    new_idx = binary_search_from(col, start_idx, v)

    if new_idx <= length(col) && col[new_idx] == v
        return new_idx
    else
        return NotFound()
    end
end

binary_search_from(col, start, v) = searchsortedfirst(@view(col[start:end]), v) + start-1

function _make_element_getter(relation::PhysicalRelation, elt)
    # TODO: don't need to do all of this.
    row_getter = RAI._make_getrow(r.relpath, r.columns)

    return idx->row_getter[idx][elt]
end

