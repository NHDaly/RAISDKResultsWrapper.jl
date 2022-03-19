
struct PhysicalRelation
    relpath::Vector{String}
    columns::JSON3.Array
end

_num_tuples(r::PhysicalRelation) = max(length(r.columns[1]), 1)

function tuples(r::PhysicalRelation)
    len = _num_tuples(r)
    tuples = (
        row_getter(i)
        for row_getter in (RAI._make_getrow(r.relpath, r.columns),)
        for i in 1:_num_tuples(r)
    )
    return TuplesIterator(len, tuples)
end

function Base.show(io::IO, r::PhysicalRelation)
    print(io, "$PhysicalRelation($(r.relpath), ")
    # recur_io = IOContext(io, :SHOWN_SET => t)
    limit = get(io, :limit, false)::Bool
    if limit  # meaning we're inside another context like an Array,
        # Also set :compact, since the Tuples vector can be quite big
        if !haskey(io, :compact)
            io = IOContext(io, :compact => true)
        end
    end
    show(io, tuples(r))
    print(io, ")")
end



