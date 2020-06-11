require "./spec_helper"

describe Compress::Brotli do
  # TODO: Write tests

  it "Test Encode No Write" do
    buf = IO::Memory.new
    br = Compress::Brotli::Writer.new(buf)
    br.close

    # check write after close
    expect_raises(IO::Error) do
      br.write "hi".to_slice
    end
  end

  it "Test Encode Empty Write" do
    buf = IO::Memory.new
    Compress::Brotli::Writer.open(buf, options: Compress::Brotli::WriterOptions.new(quality: 5_u32)) do |br|
      br.write Bytes.empty
    end
  end

  it "Test Writer" do
    # Test basic encoder usage
    input = "<html><body><H1>Hello world</H1></body></html>"
    buf = IO::Memory.new
    inp = IO::Memory.new(input)
    enc = Compress::Brotli::Writer.new(buf, options: Compress::Brotli::WriterOptions.new(quality: 1_u32))
    IO.copy inp, enc
    enc.close
    buf.rewind
    check_compressed_data buf.to_slice, input.to_slice
    inp.close
    buf.close
  end

  it "Test Encoder Stream" do
    # Test that output is streamed.
    # Adjust window size to ensure the encoder outputs at least enough bytes
    # to fill the window
    lgwin = 16
    win_size = Math.pw2ceil(lgwin)
    input = Bytes.new(8 * win_size)
    Random.new.random_bytes(input)
    half_input = input[0, input.size//2]
    buf = IO::Memory.new
    Compress::Brotli::Writer.open(buf, options: Compress::Brotli::WriterOptions.new(lgwin: lgwin.to_u32)) do |br|
      br.write half_input
    end
    # We've fed more data than the sliding window size. Check that some
    # compressed data has been output
    fail "Output length is 0 after #{half_input.size} bytes written" if buf.size == 0

    check_compressed_data(buf.to_slice, half_input)
  end

  it "Test Encoder Large Input" do
    input = Bytes.new(1000000)
    Random.new.random_bytes(input)
    buf = IO::Memory.new
    Compress::Brotli::Writer.open(buf, options: Compress::Brotli::WriterOptions.new(quality: 5_u32)) do |br|
      br.write input
    end
    buf.rewind
    check_compressed_data(buf.to_slice, input)
  end

  it "Test Encoder Flush" do
    input = Bytes.new(1000)
    Random.new.random_bytes(input)
    buf = IO::Memory.new
    Compress::Brotli::Writer.open(buf, options: Compress::Brotli::WriterOptions.new(quality: 5_u32)) do |br|
      br.write input
      br.flush
      fail "0 bytes written after flush" if buf.size == 0
    end
    buf.rewind
    check_compressed_data(buf.to_slice, input)
  end

  it "Test Reader" do
    data = "hello crystal!" * 10000
    compressed = Compress::Brotli.encode(data, Compress::Brotli::WriterOptions.new(quality: 5_u32))
    uncompressed = Compress::Brotli.decode(compressed)

    data.to_slice.should eq(uncompressed)
  end

  it "Test Decode Trailing Data" do
    data = "hello crystal!" * 10000
    compressed = Compress::Brotli.encode(data, Compress::Brotli::WriterOptions.new(quality: 5_u32))
    corrupt = Bytes.new(compressed.size + 1)
    corrupt.copy_from(compressed.to_unsafe, compressed.size)
    expect_raises(Compress::Brotli::BrotliError, "excessive input") do
      Compress::Brotli.decode(corrupt)
    end
  end
end
