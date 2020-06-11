# A read-only `IO` object to decompress data in the Brotli format.
#
# Instances of this class wrap another IO object. When you read from this instance
# instance, it reads data from the underlying IO, decompresses it, and returns
# it to the caller.
# ## Example: decompress an brotli file
# ```crystal
# require "brotli"

# string = File.open("file.br") do |file|
#    Compress::Brotli::Reader.open(file) do |br|
#      br.gets_to_end
#    end
# end
# pp string
# ```
class Compress::Brotli::Reader < IO
  include IO::Buffered

  # If `#sync_close?` is `true`, closing this IO will close the underlying IO.
  property? sync_close : Bool

  # Returns `true` if this reader is closed.
  getter? closed = false

  @state : LibBrotli::DecoderState

  # buffer size that avoids execessive round-trips between C and Crystal but doesn't waste too much
  # memory on buffering. Its arbitrarily chosen to be equal to the constant used in IO::copy
  BUF_SIZE = 4096

  # Creates an instance of XZ::Reader.
  def initialize(@io : IO, @sync_close : Bool = false)
    @buffer = Bytes.new(BUF_SIZE)
    @chunk = Bytes.empty
    alloc = LibBrotli::BrotliAllocFunc.new { |_, size| GC.malloc(size) }
    free = LibBrotli::BrotliFreeFunc.new { |_, address| GC.free(address) }
    @state = LibBrotli.decoder_create_instance(alloc, free, nil)
    raise BrotliError.new("Unable to create brotli decoder instance") if @state.nil?
  end

  # Creates a new reader from the given *io*, yields it to the given block,
  # and closes it at its end.
  def self.open(io : IO, sync_close : Bool = false)
    reader = new(io, sync_close: sync_close)
    yield reader ensure reader.close
  end

  # Creates a new reader from the given *filename*.
  def self.new(filename : String)
    new(::File.new(filename), sync_close: true)
  end

  # Creates a new reader from the given *io*, yields it to the given block,
  # and closes it at the end.
  def self.open(io : IO, sync_close = false)
    reader = new(io, sync_close: sync_close)
    yield reader ensure reader.close
  end

  # Creates a new reader from the given *filename*, yields it to the given block,
  # and closes it at the end.
  def self.open(filename : String)
    reader = new(filename)
    yield reader ensure reader.close
  end

  # Always raises `IO::Error` because this is a read-only `IO`.
  def unbuffered_write(slice : Bytes)
    raise IO::Error.new "Can't write to Brotli::Reader"
  end

  def unbuffered_read(slice : Bytes)
    check_open

    if LibBrotli.decoder_has_more_output(@state) == 0 && @chunk.empty?
      m = @io.read(@buffer)
      return m if m == 0
      @chunk = @buffer[0, m]
    end

    return 0 if slice.empty?

    n = 0
    loop do
      in_remaining = @chunk.size.to_u64
      out_remaining = slice.size.to_u64

      in_ptr = @chunk.to_unsafe
      out_ptr = slice.to_unsafe

      result = LibBrotli.decoder_decompress_stream(@state, pointerof(in_remaining), pointerof(in_ptr), pointerof(out_remaining), pointerof(out_ptr), nil)
      n = slice.size - out_remaining
      consumed = @chunk.size - in_remaining
      @chunk = @chunk[consumed..]

      case result
      when LibBrotli::DecoderResult::DecoderResultSuccess
        raise BrotliError.new("excessive input") unless @chunk.size == 0
        return n
      when LibBrotli::DecoderResult::DecoderResultError
        raise BrotliError.new LibBrotli.decoder_get_error_code(@state).to_s
      when LibBrotli::DecoderResult::DecoderResultNeedsMoreOutput
        raise BrotliError.new("Short input buffer") if n == 0
        return n
      when LibBrotli::DecoderResult::DecoderResultNeedsMoreInput
      end
      raise BrotliError.new("invalid state") unless @chunk.size == 0

      # calling @io.read may block. Don't block if we have data to return
      return n if n > 0

      # Top off the buffer
      enc_n = @io.read(@buffer)
      return 0 if enc_n == 0
      @chunk = @buffer[0, enc_n]
    end
    n
  end

  def unbuffered_flush
    raise IO::Error.new "Can't flush Brotli::Reader"
  end

  # Closes this reader.
  def unbuffered_close
    return if @closed || @state.nil?
    @closed = true

    LibBrotli.decoder_destroy_instance(@state)
    @io.close if @sync_close
  end

  def unbuffered_rewind
    check_open

    @io.rewind
    initialize(@io, @sync_close)
  end

  # :nodoc:
  def inspect(io : IO) : Nil
    to_s(io)
  end
end
