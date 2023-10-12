###
###  HeraCatcherBdaInputHeader
###

struct HeraCatcherBdaInputHeader
    good_data::Array{Int64, 0}  # ()
    bcnt::Vector{Int32}         # (BASELINES_PER_BLOCK,)
    mcnt::Vector{Int64}         # (BASELINES_PER_BLOCK,)
    ant_pair_0::Vector{Int16}   # (BASELINES_PER_BLOCK,)
    ant_pair_1::Vector{Int16}   # (BASELINES_PER_BLOCK,)
end

function HeraCatcherBdaInputHeader(p::Ptr{Nothing})
    good_data = unsafe_wrap(Array, Ptr{Int64}(p), ())
    p += sizeof(good_data[])
    bcnt = unsafe_wrap(Array, Ptr{Int32}(p), BASELINES_PER_BLOCK)
    p += sizeof(bcnt)
    mcnt = unsafe_wrap(Array, Ptr{Int64}(p), BASELINES_PER_BLOCK)
    p += sizeof(mcnt)
    ant_pair_0 = unsafe_wrap(Array, Ptr{Int16}(p), BASELINES_PER_BLOCK)
    p += sizeof(ant_pair_0)
    ant_pair_1 = unsafe_wrap(Array, Ptr{Int16}(p), BASELINES_PER_BLOCK)

    HeraCatcherBdaInputHeader(good_data, bcnt, mcnt, ant_pair_0, ant_pair_1)
end

function Base.sizeof(h::HeraCatcherBdaInputHeader)
    sizeof(h.good_data[]) +
    sizeof(h.bcnt) +
    sizeof(h.mcnt) +
    sizeof(h.ant_pair_0) +
    sizeof(h.ant_pair_1)
end

###
###  HeraCatcherBdaInputBlock
###

struct HeraCatcherBdaInputBlock <: AbstractBlock
    header::HeraCatcherBdaInputHeader
    data::Array{Complex{Int32}}  # (BASELINES_PER_BLOCK, TIME_DEMUX, N_CHAN_TOTAL, N_STOKES)
end

function HeraCatcherBdaInputBlock(p::Ptr{Nothing}, _block_size)
    header = HeraCatcherBdaInputHeader(p)
    p += pad(sizeof(header), CACHE_ALIGNMENT)
    data = unsafe_wrap(Array, Ptr{Complex{Int32}}(p),
        (BASELINES_PER_BLOCK, TIME_DEMUX, N_CHAN_TOTAL, N_STOKES)
    )

    HeraCatcherBdaInputBlock(header, data)
end

function Base.sizeof(h::HeraCatcherBdaInputBlock)
    pad(sizeof(h.header), CACHE_ALIGNMENT) + sizeof(h.data)
end
