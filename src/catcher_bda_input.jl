###
###  HeraCatcherBdaInputHeader
###

struct HeraCatcherBdaInputHeader
    good_data::Array{Int64, 0} # ()
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

struct HeraCatcherBdaInputBlock
    header::HeraCatcherBdaInputHeader
    data::Array{Complex{Int32}}  # (BASELINES_PER_BLOCK, TIME_DEMUX, N_CHAN_TOTAL, N_STOKES)
end

function HeraCatcherBdaInputBlock(p::Ptr{Nothing})
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

###
###  HeraCatcherBdaInputDatabuf
###

struct HeraCatcherBdaInputDatabuf
    header::Array{HashpipeDatabuf,0}
    block::Vector{HeraCatcherBdaInputBlock}
end

function HeraCatcherBdaInputDatabuf(p::Ptr{Nothing})
    header = unsafe_wrap(Array, Ptr{HashpipeDatabuf}(p), ())
    p += pad(sizeof(header[]), CACHE_ALIGNMENT)
    block = Vector{HeraCatcherBdaInputBlock}(undef, CATCHER_N_BLOCKS)
    for i in 1:CATCHER_N_BLOCKS
        block[i] = HeraCatcherBdaInputBlock(p)
        p += sizeof(block[i])
    end

    HeraCatcherBdaInputDatabuf(header, block)
end

function HeraCatcherBdaInputDatabuf(instance_id::Integer, databuf::Integer;
                                    keyfile=hashpipe_keyfile(), readonly=true)
    key = hashpipe_databuf_key(instance_id, databuf; keyfile)
    p = shmat(ShmId(key), readonly)
    HeraCatcherBdaInputDatabuf(p)
end

function Base.sizeof(h::HeraCatcherBdaInputDatabuf)
    pad(sizeof(h.header), CACHE_ALIGNMENT) + mapreduce(sizeof, +, h.block)
end

function Base.show(io::IO, h::HeraCatcherBdaInputDatabuf)
    shmid = h.header[].shmid
    nblks = h.header[].n_block
    blksz = h.header[].block_size
    print(io, "HeraCatcherBdaInputDatabuf@")
    print(io, shmid)
    print(io, "(")
    print(io, nblks)
    print(io, " blocks, ")
    print(io, blksz)
    print(io, " bytes each, ")
    print(io, sizeof(h))
    print(io, " bytes total)")
end
