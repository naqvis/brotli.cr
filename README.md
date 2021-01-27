# Crystal Brotli
![CI](https://github.com/naqvis/brotli.cr/workflows/CI/badge.svg)
[![GitHub release](https://img.shields.io/github/release/naqvis/brotli.svg)](https://github.com/naqvis/brotli.cr/releases)
[![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://naqvis.github.io/brotli.cr/)

Crystal bindings to the [Brotli](https://github.com/google/brotli) compression library.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     brotli:
       github: naqvis/brotli.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "brotli"
```

`brotli` shard provides both `Compress::Brotli::Reader` and `Compress::Brotli::Writer` , as well as `Compress::Brotli#decode` and `Compress::Brotli#encode` methods for quick usage.

Refer to `specs` for sample usage.

## Example: decompress an brotli file
#
```crystal
require "brotli"

string = File.open("file.br") do |file|
   Compress::Brotli::Reader.open(file) do |brotli|
     brotli.gets_to_end
   end
end
pp string
```

## Example: compress to brotli compression format
#
```crystal
require "brotli"

File.write("file.txt", "abcd")

File.open("./file.txt", "r") do |input_file|
  File.open("./file.br", "w") do |output_file|
    Compress::Brotli::Writer.open(output_file) do |brotli|
      IO.copy(input_file, brotli)
    end
  end
end
```

## Development

To run all tests:

```
crystal spec
```

## Contributing

1. Fork it (<https://github.com/naqvis/brotli.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ali Naqvi](https://github.com/naqvis) - creator and maintainer
