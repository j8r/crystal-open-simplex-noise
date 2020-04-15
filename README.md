# Open Simplex Noise

[![Build Status](https://cloud.drone.io/api/badges/j8r/crystal-open-simplex-noise/status.svg)](https://cloud.drone.io/j8r/crystal-open-simplex-noise)

This is an implementation of 2D, 3D, and 4D open simplex noise in crystal.

Original work by [doughsay](https://github.com/doughsay/crystal-open-simplex-noise).

## Installation

Add this to your application's `shard.yml`:

```yml
dependencies:
  open-simplex-noise:
    github: j8r/crystal-open-simplex-noise
```

## Usage

```crystal
require "open-simplex-noise"
```

Instantiate a noise generator using an `Int64` seed:

```crystal
noise = OpenSimplexNoise.new(12345_i64)
```

Use the `generate` method, passing in either 2, 3, or 4 `Float64`s to generate noise:

```crystal
noise.generate(1.0, 2.0)
#=> -0.08284024020120388
```

## Documentation

https://j8r.github.io/crystal-open-simplex-noise

## Examples

2D Noise:

![2d-noise](examples/output/noise2d.png)

3D Noise (2D slice):

![3d-noise](examples/output/noise3d.png)

4D Noise (2D slice):

![3d-noise](examples/output/noise4d.png)

## Credits

[doughsay](https://github.com/doughsay) Chris Dosé - original creator

This is mostly just a transliteration of the Python version from here: https://github.com/lmas/opensimplex, which itself is a transliteration of Kurt Spencer's original code (released to the public domain).

## License

[MIT](LICENSE.md)
