require "spec"
require "../src/brotli"

def check_compressed_data(compressed_data : Slice, want : Slice)
  uncompressed = Compress::Brotli.decode(compressed_data)
  if uncompressed != want
    fail "Data doesn't uncompress to the original value \n" +
         "Length of original: #{want.size}\n" +
         "Length of uncompressed: #{uncompressed.size}"
  end

  uncompressed.should eq(want)
end
