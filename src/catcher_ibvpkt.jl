###
###  HeraCatcherAppHeader
###

struct HeraCatcherAppHeader
    mcnt::Int64
    bcnt::Int32
    offset::Int32
    ant0::Int16
    ant1::Int16
    xeng_id::Int16
    payload_len::Int16
end

function Base.show(io::IO, hcah::HeraCatcherAppHeader)
    print(io, "HeraCatcherAppHeader(")
    print(io, "mcnt=");          print(io, hcah.mcnt        |>bswap)
    print(io, ", bcnt=");        print(io, hcah.bcnt        |>bswap)
    print(io, ", offset=");      print(io, hcah.offset      |>bswap)
    print(io, ", ant0=");        print(io, hcah.ant0        |>bswap)
    print(io, ", ant1=");        print(io, hcah.ant1        |>bswap)
    print(io, ", xeng_id=");     print(io, hcah.xeng_id     |>bswap)
    print(io, ", payload_len="); print(io, hcah.payload_len |>bswap)
    print(")")
end

###
###  HeraCatcherIbvpktPacket
###

struct HeraCatcherIbvpktPacket
    netheader::Vector{UInt8}                  # (NET_HEADER_SIZE,)
    appheader::Array{HeraCatcherAppHeader, 0} # ()
    # TODO figure out whether the payload has additional dimensionality
    payload::Vector{Complex{Int32}}           # (BYTES_PER_PACKET÷sizeof(Complex{Int32}),)
end

function HeraCatcherIbvpktPacket(p::Ptr{Nothing})
    netheader = unsafe_wrap(Array, Ptr{UInt8}(p), NET_HEADER_SIZE)
    p += pad(sizeof(netheader), AVX512_ALIGNMENT)
    appheader = unsafe_wrap(Array, Ptr{HeraCatcherAppHeader}(p), ())
    p += pad(sizeof(appheader), AVX512_ALIGNMENT)
    payload = unsafe_wrap(Array, Ptr{Complex{Int32}}(p),
                                 BYTES_PER_PACKET÷sizeof(Complex{Int32}))

    HeraCatcherIbvpktPacket(netheader, appheader, payload)
end

function Base.sizeof(::Type{HeraCatcherIbvpktPacket})
    pad(NET_HEADER_SIZE, AVX512_ALIGNMENT) +
    pad(sizeof(HeraCatcherAppHeader), AVX512_ALIGNMENT) +
    pad(BYTES_PER_PACKET, AVX512_ALIGNMENT)
end

###
###  HeraCatcherIbvpktBlock
###

struct HeraCatcherIbvpktBlock
    pkts::Vector{HeraCatcherIbvpktPacket}  # fld(block_size, sizeof(HeraCatcherIbvpktPacket))
end

function HeraCatcherIbvpktBlock(p::Ptr{Nothing}, block_size)
    pkts_per_block = fld(block_size, sizeof(HeraCatcherIbvpktPacket))
    pkts = Vector{HeraCatcherIbvpktPacket}(undef, pkts_per_block)
    for i in 1:pkts_per_block
        pkts[i] = HeraCatcherIbvpktPacket(p)
        p += sizeof(HeraCatcherIbvpktPacket)
    end

    HeraCatcherIbvpktBlock(pkts)
end

# Does not account for any unused space at the end of the databuf block!
function Base.sizeof(h::HeraCatcherIbvpktBlock)
    mapreduce(sizeof, +, h.pkts)
end

###
###  HeraCatcherIbvpktDatabuf
###

struct HeraCatcherIbvpktDatabuf
    header::Array{HashpipeDatabuf,0}
    block::Vector{HeraCatcherIbvpktBlock}
end

function HeraCatcherIbvpktDatabuf(p::Ptr{Nothing})
    header = unsafe_wrap(Array, Ptr{HashpipeDatabuf}(p), ())
    p += HASHPIPE_IBVPKT_DATABUF_ALIGNMENT_SIZE # 4096
    n_block = header[].n_block
    block_size = header[].block_size
    block = Vector{HeraCatcherIbvpktBlock}(undef, n_block)
    for i in 1:n_block
        block[i] = HeraCatcherIbvpktBlock(p, block_size)
        p += block_size
    end

    HeraCatcherIbvpktDatabuf(header, block)
end

function HeraCatcherIbvpktDatabuf(instance_id::Integer, databuf::Integer;
                                  keyfile=hashpipe_keyfile(), readonly=true)
    key = hashpipe_databuf_key(instance_id, databuf; keyfile)
    p = shmat(ShmId(key), readonly)
    HeraCatcherIbvpktDatabuf(p)
end

function Base.sizeof(h::HeraCatcherIbvpktDatabuf)
    pad(sizeof(h.header), CACHE_ALIGNMENT) +
    h.header[].n_block * h.header[].block_size
end

function Base.show(io::IO, h::HeraCatcherIbvpktDatabuf)
    shmid = h.header[].shmid
    nblks = h.header[].n_block
    blksz = h.header[].block_size
    print(io, "HeraCatcherIbvpktDatabuf")
    print(io, shmid)
    print(io, "(")
    print(io, nblks)
    print(io, " blocks, ")
    print(io, blksz)
    print(io, " bytes each, ")
    print(io, sizeof(h))
    print(io, " bytes total)")
end
