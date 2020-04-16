require "stumpy_png"
require "../src/open-simplex-noise"

struct ExmapleImageGenerator
  property width : Int32 = 512
  property height : Int32 = 512
  property frames : Int32 = 48
  property feature_size : Float64 = 24.0

  def initialize(seed : Int64 = 0_i64)
    @noise = OpenSimplexNoise.new seed
  end

  def generate_image(name : String, *coordinates)
    puts "Generating #{name} image..."
    canvas = StumpyPNG::Canvas.new @width, @height
    (0...@height).each do |y|
      (0...@width).each do |x|
        value = @noise.generate(x / @feature_size, y / @feature_size, *coordinates)
        gray = ((value + 1) * 128).to_i
        color = StumpyPNG::RGBA.from_rgb_n(gray, gray, gray, 8)
        canvas[x, y] = color
      end
    end
    StumpyPNG.write(canvas, "examples/output/#{name}.png")
  end
end

generator = ExmapleImageGenerator.new
generator.generate_image "noise2d"
generator.generate_image "noise3d", 0.0
generator.generate_image "noise4d", 0.0, 0.0
