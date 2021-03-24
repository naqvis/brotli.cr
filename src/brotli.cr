# `Brotli` Crystal Wrapper
module Compress::Brotli
  VERSION = "0.1.5"

  class BrotliError < Exception
  end

  def self.decode(compressed : Slice)
    buf = IO::Memory.new(compressed)
    uncompressed = Reader.open(buf) do |br|
      br.gets_to_end
    end
    uncompressed.to_slice
  end

  def self.encode(content : String, options : WriterOptions = WriterOptions.default)
    encode(content.to_slice, options)
  end

  def self.encode(content : Slice, options : WriterOptions = WriterOptions.default)
    buf = IO::Memory.new
    Brotli::Writer.open(buf) do |br|
      br.write content
    end
    buf.rewind
    buf.to_slice
  end

  def self.decoder_version_string
    version_string LibBrotli.decoder_version
  end

  def self.encoder_version_string
    version_string LibBrotli.encoder_version
  end

  private def self.version_string(v)
    sprintf "%d.%d.%d", [v >> 24, (v >> 12) & 0xFFF, v & 0xFFF]
  end
end

require "./brotli/*"
