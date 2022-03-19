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
    isempty(tuples) && return show(io, tuples)

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

