"""
Hashpipe databuf structure.  This is the first thing in every Hashpipe databuf.
"""
struct HashpipeDatabuf
    """Type of data in buffer"""
    data_type::NTuple{64, UInt8}

    """Size of each block header (bytes)"""
    header_size::Int64

    """Size of each data block (bytes)"""
    block_size::Int64

    """Number of data blocks in buffer"""
    n_block::Int32

    """ID of this shared mem segment"""
    shmid::Int32

    """ID of locking semaphore set"""
    semid::Int32
end

function Base.show(io::IO, hdb::HashpipeDatabuf)
    print(io, "HashpipeDatabuf@"); print(io, hdb.shmid);
    print(io, "(data_type=\"")
    print(io, String(UInt8[hdb.data_type...]))
    print(io, "\", header_size="); print(io, hdb.header_size)
    print(io, ", block_size=");    print(io, hdb.block_size)
    print(io, ", n_block=");       print(io, hdb.n_block)
    print(io, ", shmid=");         print(io, hdb.shmid)
    print(io, ", semid=");         print(io, hdb.semid)
    print(io, ")")
end

function hashpipe_keyfile()
    haskey(ENV, "HASHPIPE_KEYFILE") ? ENV["HASHPIPE_KEYFILE"] :
    haskey(ENV, "HOME") ? ENV["HOME"] : "/tmp"
end

function hashpipe_databuf_key(instance_id, databuf; keyfile=hashpipe_keyfile())
    if haskey(ENV, "HASHPIPE_DATABUF_KEY")
        return IPC.Key(parse(Int32, ENV["HASHPIPE_DATABUF_KEY"]))
    end
    basekey = IPC.Key(keyfile, (instance_id & 0x3f) | 0x80)
    IPC.Key(basekey.value + databuf - 1)
end