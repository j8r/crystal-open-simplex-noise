require "./constants"

struct OpenSimplexNoise
  private def extrapolate(xsb : Int32, ysb : Int32, dx : Float64, dy : Float64)
    index = @perm[(@perm[xsb & 0xFF] + ysb) & 0xFF] & 0x0E
    g1, g2 = GRADIENTS_2D[(index..index + 1)]
    g1 * dx + g2 * dy
  end

  # Generate 2D OpenSimplex noise from X,Y coordinates.
  def generate(x : Float64, y : Float64) : Float64
    # Place input coordinates onto grid.
    stretch_offset = (x + y) * STRETCH_CONSTANT_2D
    xs = x + stretch_offset
    ys = y + stretch_offset

    # Floor to get grid coordinates of rhombus (stretched square) super-cell origin.
    xsb = xs.floor.to_i
    ysb = ys.floor.to_i

    # Skew out to get actual coordinates of rhombus origin. We'll need these later.
    squish_offset = (xsb + ysb) * SQUISH_CONSTANT_2D
    xb = xsb + squish_offset
    yb = ysb + squish_offset

    # Compute grid coordinates relative to rhombus origin.
    xins = xs - xsb
    yins = ys - ysb

    # Sum those together to get a value that determines which region we're in.
    in_sum = xins + yins

    # Positions relative to origin point.
    dx0 = x - xb
    dy0 = y - yb

    value = 0

    # Contribution (1,0)
    dx1 = dx0 - 1 - SQUISH_CONSTANT_2D
    dy1 = dy0 - 0 - SQUISH_CONSTANT_2D
    attn1 = 2 - dx1 * dx1 - dy1 * dy1
    if attn1 > 0
      attn1 *= attn1
      value += attn1 * attn1 * extrapolate(xsb + 1, ysb + 0, dx1, dy1)
    end

    # Contribution (0,1)
    dx2 = dx0 - 0 - SQUISH_CONSTANT_2D
    dy2 = dy0 - 1 - SQUISH_CONSTANT_2D
    attn2 = 2 - dx2 * dx2 - dy2 * dy2
    if attn2 > 0
      attn2 *= attn2
      value += attn2 * attn2 * extrapolate(xsb + 0, ysb + 1, dx2, dy2)
    end

    if in_sum <= 1 # We're inside the triangle (2-Simplex) at (0,0)
      zins = 1 - in_sum
      if zins > xins || zins > yins # (0,0) is one of the closest two triangular vertices
        if xins > yins
          xsv_ext = xsb + 1
          ysv_ext = ysb - 1
          dx_ext = dx0 - 1
          dy_ext = dy0 + 1
        else
          xsv_ext = xsb - 1
          ysv_ext = ysb + 1
          dx_ext = dx0 + 1
          dy_ext = dy0 - 1
        end
      else # (1,0) and (0,1) are the closest two vertices.
        xsv_ext = xsb + 1
        ysv_ext = ysb + 1
        dx_ext = dx0 - 1 - 2 * SQUISH_CONSTANT_2D
        dy_ext = dy0 - 1 - 2 * SQUISH_CONSTANT_2D
      end
    else # We're inside the triangle (2-Simplex) at (1,1)
      zins = 2 - in_sum
      if zins < xins || zins < yins # (0,0) is one of the closest two triangular vertices
        if xins > yins
          xsv_ext = xsb + 2
          ysv_ext = ysb + 0
          dx_ext = dx0 - 2 - 2 * SQUISH_CONSTANT_2D
          dy_ext = dy0 + 0 - 2 * SQUISH_CONSTANT_2D
        else
          xsv_ext = xsb + 0
          ysv_ext = ysb + 2
          dx_ext = dx0 + 0 - 2 * SQUISH_CONSTANT_2D
          dy_ext = dy0 - 2 - 2 * SQUISH_CONSTANT_2D
        end
      else # (1,0) and (0,1) are the closest two vertices.
        dx_ext = dx0
        dy_ext = dy0
        xsv_ext = xsb
        ysv_ext = ysb
      end
      xsb += 1
      ysb += 1
      dx0 = dx0 - 1 - 2 * SQUISH_CONSTANT_2D
      dy0 = dy0 - 1 - 2 * SQUISH_CONSTANT_2D
    end

    # Contribution (0,0) or (1,1)
    attn0 = 2 - dx0 * dx0 - dy0 * dy0
    if attn0 > 0
      attn0 *= attn0
      value += attn0 * attn0 * extrapolate(xsb, ysb, dx0, dy0)
    end

    # Extra Vertex
    attn_ext = 2 - dx_ext * dx_ext - dy_ext * dy_ext
    if attn_ext > 0
      attn_ext *= attn_ext
      value += attn_ext * attn_ext * extrapolate(xsv_ext, ysv_ext, dx_ext, dy_ext)
    end

    value / NORM_CONSTANT_2D
  end
end
