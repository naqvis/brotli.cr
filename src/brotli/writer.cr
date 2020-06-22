# A write-only `IO` object to compress data in the Brotli format.
#
# Instances of this class wrap another `IO` object. When you write to this
# instance, it compresses the data and writes it to the underlying `IO`.
#
# NOTE: unless created with a block, `close` must be invoked after all
# data has been written to a `Brotli::Writer` instance.
#
# ### Example: compress a file
#
# ```
# require "brotli"
#
# File.write("file.txt", "abcd")
#
# File.open("./file.txt", "r") do |input_file|
#   File.open("./file.br", "w") do |output_file|
#     Compress::Brotli::Writer.open(output_file) do |br|
#       IO.copy(input_file, br)
#     end
#   end
# end
# ```
class Compress::Brotli::Writer < IO
  # If `#sync_close?` is `true`, closing this IO will close the underlying IO.
  property? sync_close : Bool

  def initialize(@output : IO, options : Brotli::WriterOptions = Brotli::WriterOptions.default, @sync_close : Bool = false)
    alloc = LibBrotli::BrotliAllocFunc.new { |_, size| GC.malloc(size) }
    free = LibBrotli::BrotliFreeFunc.new { |_, address| GC.free(address) }
    @state = LibBrotli.encoder_create_instance(alloc, free, nil)
    @closed = false
    raise BrotliError.new("Unable to create brotli encoder instance") if @state.nil?
    configure(options)
  end

  # Creates a new writer to the given *filename*.
  def self.new(filename : String, options : Brotli::WriterOptions = Brotli::WriterOptions.default)
    new(::File.new(filename, "w"), options: options, sync_close: true)
  end

  # Creates a new writer to the given *io*, yields it to the given block,
  # and closes it at the end.
  def self.open(io : IO, options : Brotli::WriterOptions = Brotli::WriterOptions.default, sync_close = false)
    writer = new(io, preset: preset, sync_close: sync_close)
    yield writer ensure writer.close
  end

  # Creates a new writer to the given *filename*, yields it to the given block,
  # and closes it at the end.
  def self.open(filename : String, options : Brotli::WriterOptions = Brotli::WriterOptions.default)
    writer = new(filename, options: options)
    yield writer ensure writer.close
  end

  # Creates a new writer for the given *io*, yields it to the given block,
  # and closes it at its end.
  def self.open(io : IO, options : Brotli::WriterOptions = Brotli::WriterOptions.default, sync_close : Bool = false)
    writer = new(io, options: options, sync_close: sync_close)
    yield writer ensure writer.close
  end

  private def configure(options)
    return if options.default?
    LibBrotli.encoder_set_parameter(@state, LibBrotli::EncoderParameter::ParamMode, options.mode)
    LibBrotli.encoder_set_parameter(@state, LibBrotli::EncoderParameter::ParamQuality, options.quality)
    LibBrotli.encoder_set_parameter(@state, LibBrotli::EncoderParameter::ParamLgwin, options.lgwin)
  end

  # Always raises `IO::Error` because this is a write-only `IO`.
  def read(slice : Bytes)
    raise IO::Error.new "Can't read from Brotli::Writer"
  end

  # See `IO#write`.
  def write(slice : Bytes) : Nil
    check_open

    return 0i64 if slice.empty?
    write_chunk slice, LibBrotli::EncoderOperation::OperationProcess
  end

  # See `IO#flush`.
  def flush
    return if @closed

    write_chunk Bytes.empty, LibBrotli::EncoderOperation::OperationFlush
  end

  # Closes this writer. Must be invoked after all data has been written.
  def close
    return if @closed || @state.nil?
    write_chunk Bytes.empty, LibBrotli::EncoderOperation::OperationFinish
    LibBrotli.encoder_destroy_instance(@state)
    @closed = true
    @output.close if @sync_close
  end

  # Returns `true` if this IO is closed.
  def closed?
    @closed
  end

  # :nodoc:
  def inspect(io : IO) : Nil
    to_s(io)
  end

  private def write_chunk(chunk : Slice, op : LibBrotli::EncoderOperation)
    raise BrotliError.new("Writer closed") if @closed || @state.nil?
    loop do
      size = chunk.size
      avail_in = size.to_u64
      avail_out = 0_u64
      ptr_in = chunk.to_unsafe
      result = LibBrotli.encoder_compress_stream(@state, op, pointerof(avail_in), pointerof(ptr_in), pointerof(avail_out), nil, nil)
      raise BrotliError.new("encode error") if result == 0

      bytes_consumed = size - avail_in
      output = LibBrotli.encoder_take_output(@state, out output_data_size)
      has_more = LibBrotli.encoder_has_more_output(@state) == 1

      chunk = chunk[bytes_consumed..]
      if output_data_size != 0
        @output.write output.to_slice(output_data_size)
      end
      break if chunk.size == 0 && !has_more
    end
  end
end

struct Compress::Brotli::WriterOptions
  # compression mode
  property mode : LibBrotli::EncoderMode
  # controls the compression speed vs compression density tradeoff. Higher the quality,
  # slower the compression. Range is 0 to 11. Defaults to 11
  getter quality : UInt32
  # Base 2 logarithm of the maximum input block size. Range is 10 to 24. Defaults to 22.
  getter lgwin : UInt32

  def initialize(@mode = LibBrotli::EncoderMode::ModeGeneric, @quality = 11_u32, @lgwin = 22_u32)
  end

  def quality=(val)
    unless 0 <= val <= 11
      raise ArgumentError.new("Invalid quality level: #{val} (must be in 0..11)")
    end
    @quality = val
  end

  def lgwin=(val)
    unless 10 <= val <= 24
      raise ArgumentError.new("Invalid lgwin value: #{val} (must be in 10..24)")
    end
    @quality = val
  end

  def self.default
    new
  end

  def default?
    self.mode == LibBrotli::EncoderMode::ModeGeneric &&
      self.quality == 11 &&
      self.lgwin == 22
  end
end
