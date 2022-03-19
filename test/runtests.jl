using RAISDKResultsWrapper
using Test

import RAI

ctx = RAI.Context(RAI.load_config()); config = (ctx, "nhd-test-1", "nhd-s");
config = (ctx, "nhd-test-1", "nhd-s");
r = RAI.exec(config..., """:a, (1;2;(3,"hi")); :b,"hi",:c,(range[2,15,1]); :x,true; :y,100 """)

@testset "RAISDKResultsWrapper.jl" begin
    cursor = output(r)

    tups = tuples(cursor)
    @test length(tups) == 19
    @test eltype(tups) == Tuple
    @test collect(tups) isa Vector{Tuple}
    @test length(collect(tups)) == 19

    show(tups)
    display(tups)
end
