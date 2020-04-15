class OpenSimplexNoise
  private def extrapolate(xsb : Int32, ysb : Int32, zsb : Int32, wsb : Int32, dx : Float64, dy : Float64, dz : Float64, dw : Float64)
    index = @perm[(@perm[(@perm[(@perm[xsb & 0xFF] + ysb) & 0xFF] + zsb) & 0xFF] + wsb) & 0xFF] & 0xFC
    g1, g2, g3, g4 = GRADIENTS_4D[(index..index + 3)]
    g1 * dx + g2 * dy + g3 * dz + g4 * dw
  end

  def generate(x, y, z, w)
    # Generate 4D OpenSimplex noise from X,Y,Z,W coordinates.

    # Place input coordinates on simplectic honeycomb.
    stretch_offset = (x + y + z + w) * STRETCH_CONSTANT_4D
    xs = x + stretch_offset
    ys = y + stretch_offset
    zs = z + stretch_offset
    ws = w + stretch_offset

    # Floor to get simplectic honeycomb coordinates of rhombo-hypercube super-cell origin.
    xsb = xs.floor.to_i
    ysb = ys.floor.to_i
    zsb = zs.floor.to_i
    wsb = ws.floor.to_i

    # Skew out to get actual coordinates of stretched rhombo-hypercube origin. We'll need these later.
    squish_offset = (xsb + ysb + zsb + wsb) * SQUISH_CONSTANT_4D
    xb = xsb + squish_offset
    yb = ysb + squish_offset
    zb = zsb + squish_offset
    wb = wsb + squish_offset

    # Compute simplectic honeycomb coordinates relative to rhombo-hypercube origin.
    xins = xs - xsb
    yins = ys - ysb
    zins = zs - zsb
    wins = ws - wsb

    # Sum those together to get a value that determines which region we're in.
    in_sum = xins + yins + zins + wins

    # Positions relative to origin po.
    dx0 = x - xb
    dy0 = y - yb
    dz0 = z - zb
    dw0 = w - wb

    value = 0
    if in_sum <= 1 # We're inside the pentachoron (4-Simplex) at (0,0,0,0)

      # Determine which two of (0,0,0,1), (0,0,1,0), (0,1,0,0), (1,0,0,0) are closest.
      a_po = 0x01
      a_score = xins
      b_po = 0x02
      b_score = yins
      if a_score >= b_score && zins > b_score
        b_score = zins
        b_po = 0x04
      elsif a_score < b_score && zins > a_score
        a_score = zins
        a_po = 0x04
      end

      if a_score >= b_score && wins > b_score
        b_score = wins
        b_po = 0x08
      elsif a_score < b_score && wins > a_score
        a_score = wins
        a_po = 0x08
      end

      # Now we determine the three lattice pos not part of the pentachoron that may contribute.
      # This depends on the closest two pentachoron vertices, including (0,0,0,0)
      uins = 1 - in_sum
      if uins > a_score || uins > b_score   # (0,0,0,0) is one of the closest two pentachoron vertices.
        c = b_score > a_score ? b_po : a_po # Our other closest vertex is the closest out of a and b.
        if (c & 0x01) == 0
          xsv_ext0 = xsb - 1
          xsv_ext1 = xsv_ext2 = xsb
          dx_ext0 = dx0 + 1
          dx_ext1 = dx_ext2 = dx0
        else
          xsv_ext0 = xsv_ext1 = xsv_ext2 = xsb + 1
          dx_ext0 = dx_ext1 = dx_ext2 = dx0 - 1
        end

        if (c & 0x02) == 0
          ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb
          dy_ext0 = dy_ext1 = dy_ext2 = dy0
          if (c & 0x01) == 0x01
            ysv_ext0 -= 1
            dy_ext0 += 1
          else
            ysv_ext1 -= 1
            dy_ext1 += 1
          end
        else
          ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb + 1
          dy_ext0 = dy_ext1 = dy_ext2 = dy0 - 1
        end

        if (c & 0x04) == 0
          zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb
          dz_ext0 = dz_ext1 = dz_ext2 = dz0
          if (c & 0x03) != 0
            if (c & 0x03) == 0x03
              zsv_ext0 -= 1
              dz_ext0 += 1
            else
              zsv_ext1 -= 1
              dz_ext1 += 1
            end
          else
            zsv_ext2 -= 1
            dz_ext2 += 1
          end
        else
          zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb + 1
          dz_ext0 = dz_ext1 = dz_ext2 = dz0 - 1
        end

        if (c & 0x08) == 0
          wsv_ext0 = wsv_ext1 = wsb
          wsv_ext2 = wsb - 1
          dw_ext0 = dw_ext1 = dw0
          dw_ext2 = dw0 + 1
        else
          wsv_ext0 = wsv_ext1 = wsv_ext2 = wsb + 1
          dw_ext0 = dw_ext1 = dw_ext2 = dw0 - 1
        end
      else                # (0,0,0,0) is not one of the closest two pentachoron vertices.
        c = (a_po | b_po) # Our three extra vertices are determined by the closest two.

        if (c & 0x01) == 0
          xsv_ext0 = xsv_ext2 = xsb
          xsv_ext1 = xsb - 1
          dx_ext0 = dx0 - 2 * SQUISH_CONSTANT_4D
          dx_ext1 = dx0 + 1 - SQUISH_CONSTANT_4D
          dx_ext2 = dx0 - SQUISH_CONSTANT_4D
        else
          xsv_ext0 = xsv_ext1 = xsv_ext2 = xsb + 1
          dx_ext0 = dx0 - 1 - 2 * SQUISH_CONSTANT_4D
          dx_ext1 = dx_ext2 = dx0 - 1 - SQUISH_CONSTANT_4D
        end

        if (c & 0x02) == 0
          ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb
          dy_ext0 = dy0 - 2 * SQUISH_CONSTANT_4D
          dy_ext1 = dy_ext2 = dy0 - SQUISH_CONSTANT_4D
          if (c & 0x01) == 0x01
            ysv_ext1 -= 1
            dy_ext1 += 1
          else
            ysv_ext2 -= 1
            dy_ext2 += 1
          end
        else
          ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb + 1
          dy_ext0 = dy0 - 1 - 2 * SQUISH_CONSTANT_4D
          dy_ext1 = dy_ext2 = dy0 - 1 - SQUISH_CONSTANT_4D
        end

        if (c & 0x04) == 0
          zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb
          dz_ext0 = dz0 - 2 * SQUISH_CONSTANT_4D
          dz_ext1 = dz_ext2 = dz0 - SQUISH_CONSTANT_4D
          if (c & 0x03) == 0x03
            zsv_ext1 -= 1
            dz_ext1 += 1
          else
            zsv_ext2 -= 1
            dz_ext2 += 1
          end
        else
          zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb + 1
          dz_ext0 = dz0 - 1 - 2 * SQUISH_CONSTANT_4D
          dz_ext1 = dz_ext2 = dz0 - 1 - SQUISH_CONSTANT_4D
        end

        if (c & 0x08) == 0
          wsv_ext0 = wsv_ext1 = wsb
          wsv_ext2 = wsb - 1
          dw_ext0 = dw0 - 2 * SQUISH_CONSTANT_4D
          dw_ext1 = dw0 - SQUISH_CONSTANT_4D
          dw_ext2 = dw0 + 1 - SQUISH_CONSTANT_4D
        else
          wsv_ext0 = wsv_ext1 = wsv_ext2 = wsb + 1
          dw_ext0 = dw0 - 1 - 2 * SQUISH_CONSTANT_4D
          dw_ext1 = dw_ext2 = dw0 - 1 - SQUISH_CONSTANT_4D
        end
      end

      # Contribution (0,0,0,0)
      attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0 - dw0 * dw0
      if attn0 > 0
        attn0 *= attn0
        value += attn0 * attn0 * extrapolate(xsb + 0, ysb + 0, zsb + 0, wsb + 0, dx0, dy0, dz0, dw0)
      end

      # Contribution (1,0,0,0)
      dx1 = dx0 - 1 - SQUISH_CONSTANT_4D
      dy1 = dy0 - 0 - SQUISH_CONSTANT_4D
      dz1 = dz0 - 0 - SQUISH_CONSTANT_4D
      dw1 = dw0 - 0 - SQUISH_CONSTANT_4D
      attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1
      if attn1 > 0
        attn1 *= attn1
        value += attn1 * attn1 * extrapolate(xsb + 1, ysb + 0, zsb + 0, wsb + 0, dx1, dy1, dz1, dw1)
      end

      # Contribution (0,1,0,0)
      dx2 = dx0 - 0 - SQUISH_CONSTANT_4D
      dy2 = dy0 - 1 - SQUISH_CONSTANT_4D
      dz2 = dz1
      dw2 = dw1
      attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2
      if attn2 > 0
        attn2 *= attn2
        value += attn2 * attn2 * extrapolate(xsb + 0, ysb + 1, zsb + 0, wsb + 0, dx2, dy2, dz2, dw2)
      end

      # Contribution (0,0,1,0)
      dx3 = dx2
      dy3 = dy1
      dz3 = dz0 - 1 - SQUISH_CONSTANT_4D
      dw3 = dw1
      attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3
      if attn3 > 0
        attn3 *= attn3
        value += attn3 * attn3 * extrapolate(xsb + 0, ysb + 0, zsb + 1, wsb + 0, dx3, dy3, dz3, dw3)
      end

      # Contribution (0,0,0,1)
      dx4 = dx2
      dy4 = dy1
      dz4 = dz1
      dw4 = dw0 - 1 - SQUISH_CONSTANT_4D
      attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4
      if attn4 > 0
        attn4 *= attn4
        value += attn4 * attn4 * extrapolate(xsb + 0, ysb + 0, zsb + 0, wsb + 1, dx4, dy4, dz4, dw4)
      end
    elsif in_sum >= 3 # We're inside the pentachoron (4-Simplex) at (1,1,1,1)
      # Determine which two of (1,1,1,0), (1,1,0,1), (1,0,1,1), (0,1,1,1) are closest.
      a_po = 0x0E
      a_score = xins
      b_po = 0x0D
      b_score = yins
      if a_score <= b_score && zins < b_score
        b_score = zins
        b_po = 0x0B
      elsif a_score > b_score && zins < a_score
        a_score = zins
        a_po = 0x0B
      end

      if a_score <= b_score && wins < b_score
        b_score = wins
        b_po = 0x07
      elsif a_score > b_score && wins < a_score
        a_score = wins
        a_po = 0x07
      end

      # Now we determine the three lattice pos not part of the pentachoron that may contribute.
      # This depends on the closest two pentachoron vertices, including (0,0,0,0)
      uins = 4 - in_sum
      if uins < a_score || uins < b_score   # (1,1,1,1) is one of the closest two pentachoron vertices.
        c = b_score < a_score ? b_po : a_po # Our other closest vertex is the closest out of a and b.

        if (c & 0x01) != 0
          xsv_ext0 = xsb + 2
          xsv_ext1 = xsv_ext2 = xsb + 1
          dx_ext0 = dx0 - 2 - 4 * SQUISH_CONSTANT_4D
          dx_ext1 = dx_ext2 = dx0 - 1 - 4 * SQUISH_CONSTANT_4D
        else
          xsv_ext0 = xsv_ext1 = xsv_ext2 = xsb
          dx_ext0 = dx_ext1 = dx_ext2 = dx0 - 4 * SQUISH_CONSTANT_4D
        end

        if (c & 0x02) != 0
          ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb + 1
          dy_ext0 = dy_ext1 = dy_ext2 = dy0 - 1 - 4 * SQUISH_CONSTANT_4D
          if (c & 0x01) != 0
            ysv_ext1 += 1
            dy_ext1 -= 1
          else
            ysv_ext0 += 1
            dy_ext0 -= 1
          end
        else
          ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb
          dy_ext0 = dy_ext1 = dy_ext2 = dy0 - 4 * SQUISH_CONSTANT_4D
        end

        if (c & 0x04) != 0
          zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb + 1
          dz_ext0 = dz_ext1 = dz_ext2 = dz0 - 1 - 4 * SQUISH_CONSTANT_4D
          if (c & 0x03) != 0x03
            if (c & 0x03) == 0
              zsv_ext0 += 1
              dz_ext0 -= 1
            else
              zsv_ext1 += 1
              dz_ext1 -= 1
            end
          else
            zsv_ext2 += 1
            dz_ext2 -= 1
          end
        else
          zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb
          dz_ext0 = dz_ext1 = dz_ext2 = dz0 - 4 * SQUISH_CONSTANT_4D
        end

        if (c & 0x08) != 0
          wsv_ext0 = wsv_ext1 = wsb + 1
          wsv_ext2 = wsb + 2
          dw_ext0 = dw_ext1 = dw0 - 1 - 4 * SQUISH_CONSTANT_4D
          dw_ext2 = dw0 - 2 - 4 * SQUISH_CONSTANT_4D
        else
          wsv_ext0 = wsv_ext1 = wsv_ext2 = wsb
          dw_ext0 = dw_ext1 = dw_ext2 = dw0 - 4 * SQUISH_CONSTANT_4D
        end
      else                # (1,1,1,1) is not one of the closest two pentachoron vertices.
        c = (a_po & b_po) # Our three extra vertices are determined by the closest two.

        if (c & 0x01) != 0
          xsv_ext0 = xsv_ext2 = xsb + 1
          xsv_ext1 = xsb + 2
          dx_ext0 = dx0 - 1 - 2 * SQUISH_CONSTANT_4D
          dx_ext1 = dx0 - 2 - 3 * SQUISH_CONSTANT_4D
          dx_ext2 = dx0 - 1 - 3 * SQUISH_CONSTANT_4D
        else
          xsv_ext0 = xsv_ext1 = xsv_ext2 = xsb
          dx_ext0 = dx0 - 2 * SQUISH_CONSTANT_4D
          dx_ext1 = dx_ext2 = dx0 - 3 * SQUISH_CONSTANT_4D
        end

        if (c & 0x02) != 0
          ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb + 1
          dy_ext0 = dy0 - 1 - 2 * SQUISH_CONSTANT_4D
          dy_ext1 = dy_ext2 = dy0 - 1 - 3 * SQUISH_CONSTANT_4D
          if (c & 0x01) != 0
            ysv_ext2 += 1
            dy_ext2 -= 1
          else
            ysv_ext1 += 1
            dy_ext1 -= 1
          end
        else
          ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb
          dy_ext0 = dy0 - 2 * SQUISH_CONSTANT_4D
          dy_ext1 = dy_ext2 = dy0 - 3 * SQUISH_CONSTANT_4D
        end

        if (c & 0x04) != 0
          zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb + 1
          dz_ext0 = dz0 - 1 - 2 * SQUISH_CONSTANT_4D
          dz_ext1 = dz_ext2 = dz0 - 1 - 3 * SQUISH_CONSTANT_4D
          if (c & 0x03) != 0
            zsv_ext2 += 1
            dz_ext2 -= 1
          else
            zsv_ext1 += 1
            dz_ext1 -= 1
          end
        else
          zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb
          dz_ext0 = dz0 - 2 * SQUISH_CONSTANT_4D
          dz_ext1 = dz_ext2 = dz0 - 3 * SQUISH_CONSTANT_4D
        end

        if (c & 0x08) != 0
          wsv_ext0 = wsv_ext1 = wsb + 1
          wsv_ext2 = wsb + 2
          dw_ext0 = dw0 - 1 - 2 * SQUISH_CONSTANT_4D
          dw_ext1 = dw0 - 1 - 3 * SQUISH_CONSTANT_4D
          dw_ext2 = dw0 - 2 - 3 * SQUISH_CONSTANT_4D
        else
          wsv_ext0 = wsv_ext1 = wsv_ext2 = wsb
          dw_ext0 = dw0 - 2 * SQUISH_CONSTANT_4D
          dw_ext1 = dw_ext2 = dw0 - 3 * SQUISH_CONSTANT_4D
        end
      end

      # Contribution (1,1,1,0)
      dx4 = dx0 - 1 - 3 * SQUISH_CONSTANT_4D
      dy4 = dy0 - 1 - 3 * SQUISH_CONSTANT_4D
      dz4 = dz0 - 1 - 3 * SQUISH_CONSTANT_4D
      dw4 = dw0 - 3 * SQUISH_CONSTANT_4D
      attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4
      if attn4 > 0
        attn4 *= attn4
        value += attn4 * attn4 * extrapolate(xsb + 1, ysb + 1, zsb + 1, wsb + 0, dx4, dy4, dz4, dw4)
      end

      # Contribution (1,1,0,1)
      dx3 = dx4
      dy3 = dy4
      dz3 = dz0 - 3 * SQUISH_CONSTANT_4D
      dw3 = dw0 - 1 - 3 * SQUISH_CONSTANT_4D
      attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3
      if attn3 > 0
        attn3 *= attn3
        value += attn3 * attn3 * extrapolate(xsb + 1, ysb + 1, zsb + 0, wsb + 1, dx3, dy3, dz3, dw3)
      end

      # Contribution (1,0,1,1)
      dx2 = dx4
      dy2 = dy0 - 3 * SQUISH_CONSTANT_4D
      dz2 = dz4
      dw2 = dw3
      attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2
      if attn2 > 0
        attn2 *= attn2
        value += attn2 * attn2 * extrapolate(xsb + 1, ysb + 0, zsb + 1, wsb + 1, dx2, dy2, dz2, dw2)
      end

      # Contribution (0,1,1,1)
      dx1 = dx0 - 3 * SQUISH_CONSTANT_4D
      dz1 = dz4
      dy1 = dy4
      dw1 = dw3
      attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1
      if attn1 > 0
        attn1 *= attn1
        value += attn1 * attn1 * extrapolate(xsb + 0, ysb + 1, zsb + 1, wsb + 1, dx1, dy1, dz1, dw1)
      end

      # Contribution (1,1,1,1)
      dx0 = dx0 - 1 - 4 * SQUISH_CONSTANT_4D
      dy0 = dy0 - 1 - 4 * SQUISH_CONSTANT_4D
      dz0 = dz0 - 1 - 4 * SQUISH_CONSTANT_4D
      dw0 = dw0 - 1 - 4 * SQUISH_CONSTANT_4D
      attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0 - dw0 * dw0
      if attn0 > 0
        attn0 *= attn0
        value += attn0 * attn0 * extrapolate(xsb + 1, ysb + 1, zsb + 1, wsb + 1, dx0, dy0, dz0, dw0)
      end
    elsif in_sum <= 2 # We're inside the first dispentachoron (Rectified 4-Simplex)
      a_is_bigger_side = true
      b_is_bigger_side = true

      # Decide between (1,1,0,0) and (0,0,1,1)
      if xins + yins > zins + wins
        a_score = xins + yins
        a_po = 0x03
      else
        a_score = zins + wins
        a_po = 0x0C
      end

      # Decide between (1,0,1,0) and (0,1,0,1)
      if xins + zins > yins + wins
        b_score = xins + zins
        b_po = 0x05
      else
        b_score = yins + wins
        b_po = 0x0A
      end

      # Closer between (1,0,0,1) and (0,1,1,0) will replace the further of a and b, if closer.
      if xins + wins > yins + zins
        score = xins + wins
        if a_score >= b_score && score > b_score
          b_score = score
          b_po = 0x09
        elsif a_score < b_score && score > a_score
          a_score = score
          a_po = 0x09
        end
      else
        score = yins + zins
        if a_score >= b_score && score > b_score
          b_score = score
          b_po = 0x06
        elsif a_score < b_score && score > a_score
          a_score = score
          a_po = 0x06
        end
      end

      # Decide if (1,0,0,0) is closer.
      p1 = 2 - in_sum + xins
      if a_score >= b_score && p1 > b_score
        b_score = p1
        b_po = 0x01
        b_is_bigger_side = false
      elsif a_score < b_score && p1 > a_score
        a_score = p1
        a_po = 0x01
        a_is_bigger_side = false
      end

      # Decide if (0,1,0,0) is closer.
      p2 = 2 - in_sum + yins
      if a_score >= b_score && p2 > b_score
        b_score = p2
        b_po = 0x02
        b_is_bigger_side = false
      elsif a_score < b_score && p2 > a_score
        a_score = p2
        a_po = 0x02
        a_is_bigger_side = false
      end

      # Decide if (0,0,1,0) is closer.
      p3 = 2 - in_sum + zins
      if a_score >= b_score && p3 > b_score
        b_score = p3
        b_po = 0x04
        b_is_bigger_side = false
      elsif a_score < b_score && p3 > a_score
        a_score = p3
        a_po = 0x04
        a_is_bigger_side = false
      end

      # Decide if (0,0,0,1) is closer.
      p4 = 2 - in_sum + wins
      if a_score >= b_score && p4 > b_score
        b_po = 0x08
        b_is_bigger_side = false
      elsif a_score < b_score && p4 > a_score
        a_po = 0x08
        a_is_bigger_side = false
      end

      # Where each of the two closest pos are determines how the extra three vertices are calculated.
      if a_is_bigger_side == b_is_bigger_side
        if a_is_bigger_side # Both closest pos on the bigger side
          c1 = (a_po | b_po)
          c2 = (a_po & b_po)
          if (c1 & 0x01) == 0
            xsv_ext0 = xsb
            xsv_ext1 = xsb - 1
            dx_ext0 = dx0 - 3 * SQUISH_CONSTANT_4D
            dx_ext1 = dx0 + 1 - 2 * SQUISH_CONSTANT_4D
          else
            xsv_ext0 = xsv_ext1 = xsb + 1
            dx_ext0 = dx0 - 1 - 3 * SQUISH_CONSTANT_4D
            dx_ext1 = dx0 - 1 - 2 * SQUISH_CONSTANT_4D
          end

          if (c1 & 0x02) == 0
            ysv_ext0 = ysb
            ysv_ext1 = ysb - 1
            dy_ext0 = dy0 - 3 * SQUISH_CONSTANT_4D
            dy_ext1 = dy0 + 1 - 2 * SQUISH_CONSTANT_4D
          else
            ysv_ext0 = ysv_ext1 = ysb + 1
            dy_ext0 = dy0 - 1 - 3 * SQUISH_CONSTANT_4D
            dy_ext1 = dy0 - 1 - 2 * SQUISH_CONSTANT_4D
          end

          if (c1 & 0x04) == 0
            zsv_ext0 = zsb
            zsv_ext1 = zsb - 1
            dz_ext0 = dz0 - 3 * SQUISH_CONSTANT_4D
            dz_ext1 = dz0 + 1 - 2 * SQUISH_CONSTANT_4D
          else
            zsv_ext0 = zsv_ext1 = zsb + 1
            dz_ext0 = dz0 - 1 - 3 * SQUISH_CONSTANT_4D
            dz_ext1 = dz0 - 1 - 2 * SQUISH_CONSTANT_4D
          end

          if (c1 & 0x08) == 0
            wsv_ext0 = wsb
            wsv_ext1 = wsb - 1
            dw_ext0 = dw0 - 3 * SQUISH_CONSTANT_4D
            dw_ext1 = dw0 + 1 - 2 * SQUISH_CONSTANT_4D
          else
            wsv_ext0 = wsv_ext1 = wsb + 1
            dw_ext0 = dw0 - 1 - 3 * SQUISH_CONSTANT_4D
            dw_ext1 = dw0 - 1 - 2 * SQUISH_CONSTANT_4D
          end

          # One combination is a _permutation of (0,0,0,2) based on c2
          xsv_ext2 = xsb
          ysv_ext2 = ysb
          zsv_ext2 = zsb
          wsv_ext2 = wsb
          dx_ext2 = dx0 - 2 * SQUISH_CONSTANT_4D
          dy_ext2 = dy0 - 2 * SQUISH_CONSTANT_4D
          dz_ext2 = dz0 - 2 * SQUISH_CONSTANT_4D
          dw_ext2 = dw0 - 2 * SQUISH_CONSTANT_4D
          if (c2 & 0x01) != 0
            xsv_ext2 += 2
            dx_ext2 -= 2
          elsif (c2 & 0x02) != 0
            ysv_ext2 += 2
            dy_ext2 -= 2
          elsif (c2 & 0x04) != 0
            zsv_ext2 += 2
            dz_ext2 -= 2
          else
            wsv_ext2 += 2
            dw_ext2 -= 2
          end
        else # Both closest pos on the smaller side
          # One of the two extra pos is (0,0,0,0)
          xsv_ext2 = xsb
          ysv_ext2 = ysb
          zsv_ext2 = zsb
          wsv_ext2 = wsb
          dx_ext2 = dx0
          dy_ext2 = dy0
          dz_ext2 = dz0
          dw_ext2 = dw0

          # Other two pos are based on the omitted axes.
          c = (a_po | b_po)

          if (c & 0x01) == 0
            xsv_ext0 = xsb - 1
            xsv_ext1 = xsb
            dx_ext0 = dx0 + 1 - SQUISH_CONSTANT_4D
            dx_ext1 = dx0 - SQUISH_CONSTANT_4D
          else
            xsv_ext0 = xsv_ext1 = xsb + 1
            dx_ext0 = dx_ext1 = dx0 - 1 - SQUISH_CONSTANT_4D
          end

          if (c & 0x02) == 0
            ysv_ext0 = ysv_ext1 = ysb
            dy_ext0 = dy_ext1 = dy0 - SQUISH_CONSTANT_4D
            if (c & 0x01) == 0x01
              ysv_ext0 -= 1
              dy_ext0 += 1
            else
              ysv_ext1 -= 1
              dy_ext1 += 1
            end
          else
            ysv_ext0 = ysv_ext1 = ysb + 1
            dy_ext0 = dy_ext1 = dy0 - 1 - SQUISH_CONSTANT_4D
          end

          if (c & 0x04) == 0
            zsv_ext0 = zsv_ext1 = zsb
            dz_ext0 = dz_ext1 = dz0 - SQUISH_CONSTANT_4D
            if (c & 0x03) == 0x03
              zsv_ext0 -= 1
              dz_ext0 += 1
            else
              zsv_ext1 -= 1
              dz_ext1 += 1
            end
          else
            zsv_ext0 = zsv_ext1 = zsb + 1
            dz_ext0 = dz_ext1 = dz0 - 1 - SQUISH_CONSTANT_4D
          end

          if (c & 0x08) == 0
            wsv_ext0 = wsb
            wsv_ext1 = wsb - 1
            dw_ext0 = dw0 - SQUISH_CONSTANT_4D
            dw_ext1 = dw0 + 1 - SQUISH_CONSTANT_4D
          else
            wsv_ext0 = wsv_ext1 = wsb + 1
            dw_ext0 = dw_ext1 = dw0 - 1 - SQUISH_CONSTANT_4D
          end
        end
      else # One po on each "side"
        if a_is_bigger_side
          c1 = a_po
          c2 = b_po
        else
          c1 = b_po
          c2 = a_po
        end

        # Two contributions are the bigger-sided po with each 0 replaced with -1.
        if (c1 & 0x01) == 0
          xsv_ext0 = xsb - 1
          xsv_ext1 = xsb
          dx_ext0 = dx0 + 1 - SQUISH_CONSTANT_4D
          dx_ext1 = dx0 - SQUISH_CONSTANT_4D
        else
          xsv_ext0 = xsv_ext1 = xsb + 1
          dx_ext0 = dx_ext1 = dx0 - 1 - SQUISH_CONSTANT_4D
        end

        if (c1 & 0x02) == 0
          ysv_ext0 = ysv_ext1 = ysb
          dy_ext0 = dy_ext1 = dy0 - SQUISH_CONSTANT_4D
          if (c1 & 0x01) == 0x01
            ysv_ext0 -= 1
            dy_ext0 += 1
          else
            ysv_ext1 -= 1
            dy_ext1 += 1
          end
        else
          ysv_ext0 = ysv_ext1 = ysb + 1
          dy_ext0 = dy_ext1 = dy0 - 1 - SQUISH_CONSTANT_4D
        end

        if (c1 & 0x04) == 0
          zsv_ext0 = zsv_ext1 = zsb
          dz_ext0 = dz_ext1 = dz0 - SQUISH_CONSTANT_4D
          if (c1 & 0x03) == 0x03
            zsv_ext0 -= 1
            dz_ext0 += 1
          else
            zsv_ext1 -= 1
            dz_ext1 += 1
          end
        else
          zsv_ext0 = zsv_ext1 = zsb + 1
          dz_ext0 = dz_ext1 = dz0 - 1 - SQUISH_CONSTANT_4D
        end

        if (c1 & 0x08) == 0
          wsv_ext0 = wsb
          wsv_ext1 = wsb - 1
          dw_ext0 = dw0 - SQUISH_CONSTANT_4D
          dw_ext1 = dw0 + 1 - SQUISH_CONSTANT_4D
        else
          wsv_ext0 = wsv_ext1 = wsb + 1
          dw_ext0 = dw_ext1 = dw0 - 1 - SQUISH_CONSTANT_4D
        end

        # One contribution is a _permutation of (0,0,0,2) based on the smaller-sided po
        xsv_ext2 = xsb
        ysv_ext2 = ysb
        zsv_ext2 = zsb
        wsv_ext2 = wsb
        dx_ext2 = dx0 - 2 * SQUISH_CONSTANT_4D
        dy_ext2 = dy0 - 2 * SQUISH_CONSTANT_4D
        dz_ext2 = dz0 - 2 * SQUISH_CONSTANT_4D
        dw_ext2 = dw0 - 2 * SQUISH_CONSTANT_4D
        if (c2 & 0x01) != 0
          xsv_ext2 += 2
          dx_ext2 -= 2
        elsif (c2 & 0x02) != 0
          ysv_ext2 += 2
          dy_ext2 -= 2
        elsif (c2 & 0x04) != 0
          zsv_ext2 += 2
          dz_ext2 -= 2
        else
          wsv_ext2 += 2
          dw_ext2 -= 2
        end
      end

      # Contribution (1,0,0,0)
      dx1 = dx0 - 1 - SQUISH_CONSTANT_4D
      dy1 = dy0 - 0 - SQUISH_CONSTANT_4D
      dz1 = dz0 - 0 - SQUISH_CONSTANT_4D
      dw1 = dw0 - 0 - SQUISH_CONSTANT_4D
      attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1
      if attn1 > 0
        attn1 *= attn1
        value += attn1 * attn1 * extrapolate(xsb + 1, ysb + 0, zsb + 0, wsb + 0, dx1, dy1, dz1, dw1)
      end

      # Contribution (0,1,0,0)
      dx2 = dx0 - 0 - SQUISH_CONSTANT_4D
      dy2 = dy0 - 1 - SQUISH_CONSTANT_4D
      dz2 = dz1
      dw2 = dw1
      attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2
      if attn2 > 0
        attn2 *= attn2
        value += attn2 * attn2 * extrapolate(xsb + 0, ysb + 1, zsb + 0, wsb + 0, dx2, dy2, dz2, dw2)
      end

      # Contribution (0,0,1,0)
      dx3 = dx2
      dy3 = dy1
      dz3 = dz0 - 1 - SQUISH_CONSTANT_4D
      dw3 = dw1
      attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3
      if attn3 > 0
        attn3 *= attn3
        value += attn3 * attn3 * extrapolate(xsb + 0, ysb + 0, zsb + 1, wsb + 0, dx3, dy3, dz3, dw3)
      end

      # Contribution (0,0,0,1)
      dx4 = dx2
      dy4 = dy1
      dz4 = dz1
      dw4 = dw0 - 1 - SQUISH_CONSTANT_4D
      attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4
      if attn4 > 0
        attn4 *= attn4
        value += attn4 * attn4 * extrapolate(xsb + 0, ysb + 0, zsb + 0, wsb + 1, dx4, dy4, dz4, dw4)
      end

      # Contribution (1,1,0,0)
      dx5 = dx0 - 1 - 2 * SQUISH_CONSTANT_4D
      dy5 = dy0 - 1 - 2 * SQUISH_CONSTANT_4D
      dz5 = dz0 - 0 - 2 * SQUISH_CONSTANT_4D
      dw5 = dw0 - 0 - 2 * SQUISH_CONSTANT_4D
      attn5 = 2 - dx5 * dx5 - dy5 * dy5 - dz5 * dz5 - dw5 * dw5
      if attn5 > 0
        attn5 *= attn5
        value += attn5 * attn5 * extrapolate(xsb + 1, ysb + 1, zsb + 0, wsb + 0, dx5, dy5, dz5, dw5)
      end

      # Contribution (1,0,1,0)
      dx6 = dx0 - 1 - 2 * SQUISH_CONSTANT_4D
      dy6 = dy0 - 0 - 2 * SQUISH_CONSTANT_4D
      dz6 = dz0 - 1 - 2 * SQUISH_CONSTANT_4D
      dw6 = dw0 - 0 - 2 * SQUISH_CONSTANT_4D
      attn6 = 2 - dx6 * dx6 - dy6 * dy6 - dz6 * dz6 - dw6 * dw6
      if attn6 > 0
        attn6 *= attn6
        value += attn6 * attn6 * extrapolate(xsb + 1, ysb + 0, zsb + 1, wsb + 0, dx6, dy6, dz6, dw6)
      end

      # Contribution (1,0,0,1)
      dx7 = dx0 - 1 - 2 * SQUISH_CONSTANT_4D
      dy7 = dy0 - 0 - 2 * SQUISH_CONSTANT_4D
      dz7 = dz0 - 0 - 2 * SQUISH_CONSTANT_4D
      dw7 = dw0 - 1 - 2 * SQUISH_CONSTANT_4D
      attn7 = 2 - dx7 * dx7 - dy7 * dy7 - dz7 * dz7 - dw7 * dw7
      if attn7 > 0
        attn7 *= attn7
        value += attn7 * attn7 * extrapolate(xsb + 1, ysb + 0, zsb + 0, wsb + 1, dx7, dy7, dz7, dw7)
      end

      # Contribution (0,1,1,0)
      dx8 = dx0 - 0 - 2 * SQUISH_CONSTANT_4D
      dy8 = dy0 - 1 - 2 * SQUISH_CONSTANT_4D
      dz8 = dz0 - 1 - 2 * SQUISH_CONSTANT_4D
      dw8 = dw0 - 0 - 2 * SQUISH_CONSTANT_4D
      attn8 = 2 - dx8 * dx8 - dy8 * dy8 - dz8 * dz8 - dw8 * dw8
      if attn8 > 0
        attn8 *= attn8
        value += attn8 * attn8 * extrapolate(xsb + 0, ysb + 1, zsb + 1, wsb + 0, dx8, dy8, dz8, dw8)
      end

      # Contribution (0,1,0,1)
      dx9 = dx0 - 0 - 2 * SQUISH_CONSTANT_4D
      dy9 = dy0 - 1 - 2 * SQUISH_CONSTANT_4D
      dz9 = dz0 - 0 - 2 * SQUISH_CONSTANT_4D
      dw9 = dw0 - 1 - 2 * SQUISH_CONSTANT_4D
      attn9 = 2 - dx9 * dx9 - dy9 * dy9 - dz9 * dz9 - dw9 * dw9
      if attn9 > 0
        attn9 *= attn9
        value += attn9 * attn9 * extrapolate(xsb + 0, ysb + 1, zsb + 0, wsb + 1, dx9, dy9, dz9, dw9)
      end

      # Contribution (0,0,1,1)
      dx10 = dx0 - 0 - 2 * SQUISH_CONSTANT_4D
      dy10 = dy0 - 0 - 2 * SQUISH_CONSTANT_4D
      dz10 = dz0 - 1 - 2 * SQUISH_CONSTANT_4D
      dw10 = dw0 - 1 - 2 * SQUISH_CONSTANT_4D
      attn10 = 2 - dx10 * dx10 - dy10 * dy10 - dz10 * dz10 - dw10 * dw10
      if attn10 > 0
        attn10 *= attn10
        value += attn10 * attn10 * extrapolate(xsb + 0, ysb + 0, zsb + 1, wsb + 1, dx10, dy10, dz10, dw10)
      end
    else # We're inside the second dispentachoron (Rectified 4-Simplex)
      a_is_bigger_side = true
      b_is_bigger_side = true

      # Decide between (0,0,1,1) and (1,1,0,0)
      if xins + yins < zins + wins
        a_score = xins + yins
        a_po = 0x0C
      else
        a_score = zins + wins
        a_po = 0x03
      end

      # Decide between (0,1,0,1) and (1,0,1,0)
      if xins + zins < yins + wins
        b_score = xins + zins
        b_po = 0x0A
      else
        b_score = yins + wins
        b_po = 0x05
      end

      # Closer between (0,1,1,0) and (1,0,0,1) will replace the further of a and b, if closer.
      if xins + wins < yins + zins
        score = xins + wins
        if a_score <= b_score && score < b_score
          b_score = score
          b_po = 0x06
        elsif a_score > b_score && score < a_score
          a_score = score
          a_po = 0x06
        end
      else
        score = yins + zins
        if a_score <= b_score && score < b_score
          b_score = score
          b_po = 0x09
        elsif a_score > b_score && score < a_score
          a_score = score
          a_po = 0x09
        end
      end

      # Decide if (0,1,1,1) is closer.
      p1 = 3 - in_sum + xins
      if a_score <= b_score && p1 < b_score
        b_score = p1
        b_po = 0x0E
        b_is_bigger_side = false
      elsif a_score > b_score && p1 < a_score
        a_score = p1
        a_po = 0x0E
        a_is_bigger_side = false
      end

      # Decide if (1,0,1,1) is closer.
      p2 = 3 - in_sum + yins
      if a_score <= b_score && p2 < b_score
        b_score = p2
        b_po = 0x0D
        b_is_bigger_side = false
      elsif a_score > b_score && p2 < a_score
        a_score = p2
        a_po = 0x0D
        a_is_bigger_side = false
      end

      # Decide if (1,1,0,1) is closer.
      p3 = 3 - in_sum + zins
      if a_score <= b_score && p3 < b_score
        b_score = p3
        b_po = 0x0B
        b_is_bigger_side = false
      elsif a_score > b_score && p3 < a_score
        a_score = p3
        a_po = 0x0B
        a_is_bigger_side = false
      end

      # Decide if (1,1,1,0) is closer.
      p4 = 3 - in_sum + wins
      if a_score <= b_score && p4 < b_score
        b_po = 0x07
        b_is_bigger_side = false
      elsif a_score > b_score && p4 < a_score
        a_po = 0x07
        a_is_bigger_side = false
      end

      # Where each of the two closest pos are determines how the extra three vertices are calculated.
      if a_is_bigger_side == b_is_bigger_side
        if a_is_bigger_side # Both closest pos on the bigger side
          c1 = (a_po & b_po)
          c2 = (a_po | b_po)

          # Two contributions are _permutations of (0,0,0,1) and (0,0,0,2) based on c1
          xsv_ext0 = xsv_ext1 = xsb
          ysv_ext0 = ysv_ext1 = ysb
          zsv_ext0 = zsv_ext1 = zsb
          wsv_ext0 = wsv_ext1 = wsb
          dx_ext0 = dx0 - SQUISH_CONSTANT_4D
          dy_ext0 = dy0 - SQUISH_CONSTANT_4D
          dz_ext0 = dz0 - SQUISH_CONSTANT_4D
          dw_ext0 = dw0 - SQUISH_CONSTANT_4D
          dx_ext1 = dx0 - 2 * SQUISH_CONSTANT_4D
          dy_ext1 = dy0 - 2 * SQUISH_CONSTANT_4D
          dz_ext1 = dz0 - 2 * SQUISH_CONSTANT_4D
          dw_ext1 = dw0 - 2 * SQUISH_CONSTANT_4D
          if (c1 & 0x01) != 0
            xsv_ext0 += 1
            dx_ext0 -= 1
            xsv_ext1 += 2
            dx_ext1 -= 2
          elsif (c1 & 0x02) != 0
            ysv_ext0 += 1
            dy_ext0 -= 1
            ysv_ext1 += 2
            dy_ext1 -= 2
          elsif (c1 & 0x04) != 0
            zsv_ext0 += 1
            dz_ext0 -= 1
            zsv_ext1 += 2
            dz_ext1 -= 2
          else
            wsv_ext0 += 1
            dw_ext0 -= 1
            wsv_ext1 += 2
            dw_ext1 -= 2
          end

          # One contribution is a _permutation of (1,1,1,-1) based on c2
          xsv_ext2 = xsb + 1
          ysv_ext2 = ysb + 1
          zsv_ext2 = zsb + 1
          wsv_ext2 = wsb + 1
          dx_ext2 = dx0 - 1 - 2 * SQUISH_CONSTANT_4D
          dy_ext2 = dy0 - 1 - 2 * SQUISH_CONSTANT_4D
          dz_ext2 = dz0 - 1 - 2 * SQUISH_CONSTANT_4D
          dw_ext2 = dw0 - 1 - 2 * SQUISH_CONSTANT_4D
          if (c2 & 0x01) == 0
            xsv_ext2 -= 2
            dx_ext2 += 2
          elsif (c2 & 0x02) == 0
            ysv_ext2 -= 2
            dy_ext2 += 2
          elsif (c2 & 0x04) == 0
            zsv_ext2 -= 2
            dz_ext2 += 2
          else
            wsv_ext2 -= 2
            dw_ext2 += 2
          end
        else # Both closest pos on the smaller side
          # One of the two extra pos is (1,1,1,1)
          xsv_ext2 = xsb + 1
          ysv_ext2 = ysb + 1
          zsv_ext2 = zsb + 1
          wsv_ext2 = wsb + 1
          dx_ext2 = dx0 - 1 - 4 * SQUISH_CONSTANT_4D
          dy_ext2 = dy0 - 1 - 4 * SQUISH_CONSTANT_4D
          dz_ext2 = dz0 - 1 - 4 * SQUISH_CONSTANT_4D
          dw_ext2 = dw0 - 1 - 4 * SQUISH_CONSTANT_4D

          # Other two pos are based on the shared axes.
          c = (a_po & b_po)
          if (c & 0x01) != 0
            xsv_ext0 = xsb + 2
            xsv_ext1 = xsb + 1
            dx_ext0 = dx0 - 2 - 3 * SQUISH_CONSTANT_4D
            dx_ext1 = dx0 - 1 - 3 * SQUISH_CONSTANT_4D
          else
            xsv_ext0 = xsv_ext1 = xsb
            dx_ext0 = dx_ext1 = dx0 - 3 * SQUISH_CONSTANT_4D
          end

          if (c & 0x02) != 0
            ysv_ext0 = ysv_ext1 = ysb + 1
            dy_ext0 = dy_ext1 = dy0 - 1 - 3 * SQUISH_CONSTANT_4D
            if (c & 0x01) == 0
              ysv_ext0 += 1
              dy_ext0 -= 1
            else
              ysv_ext1 += 1
              dy_ext1 -= 1
            end
          else
            ysv_ext0 = ysv_ext1 = ysb
            dy_ext0 = dy_ext1 = dy0 - 3 * SQUISH_CONSTANT_4D
          end

          if (c & 0x04) != 0
            zsv_ext0 = zsv_ext1 = zsb + 1
            dz_ext0 = dz_ext1 = dz0 - 1 - 3 * SQUISH_CONSTANT_4D
            if (c & 0x03) == 0
              zsv_ext0 += 1
              dz_ext0 -= 1
            else
              zsv_ext1 += 1
              dz_ext1 -= 1
            end
          else
            zsv_ext0 = zsv_ext1 = zsb
            dz_ext0 = dz_ext1 = dz0 - 3 * SQUISH_CONSTANT_4D
          end

          if (c & 0x08) != 0
            wsv_ext0 = wsb + 1
            wsv_ext1 = wsb + 2
            dw_ext0 = dw0 - 1 - 3 * SQUISH_CONSTANT_4D
            dw_ext1 = dw0 - 2 - 3 * SQUISH_CONSTANT_4D
          else
            wsv_ext0 = wsv_ext1 = wsb
            dw_ext0 = dw_ext1 = dw0 - 3 * SQUISH_CONSTANT_4D
          end
        end
      else # One po on each "side"
        if a_is_bigger_side
          c1 = a_po
          c2 = b_po
        else
          c1 = b_po
          c2 = a_po
        end

        # Two contributions are the bigger-sided po with each 1 replaced with 2.
        if (c1 & 0x01) != 0
          xsv_ext0 = xsb + 2
          xsv_ext1 = xsb + 1
          dx_ext0 = dx0 - 2 - 3 * SQUISH_CONSTANT_4D
          dx_ext1 = dx0 - 1 - 3 * SQUISH_CONSTANT_4D
        else
          xsv_ext0 = xsv_ext1 = xsb
          dx_ext0 = dx_ext1 = dx0 - 3 * SQUISH_CONSTANT_4D
        end

        if (c1 & 0x02) != 0
          ysv_ext0 = ysv_ext1 = ysb + 1
          dy_ext0 = dy_ext1 = dy0 - 1 - 3 * SQUISH_CONSTANT_4D
          if (c1 & 0x01) == 0
            ysv_ext0 += 1
            dy_ext0 -= 1
          else
            ysv_ext1 += 1
            dy_ext1 -= 1
          end
        else
          ysv_ext0 = ysv_ext1 = ysb
          dy_ext0 = dy_ext1 = dy0 - 3 * SQUISH_CONSTANT_4D
        end

        if (c1 & 0x04) != 0
          zsv_ext0 = zsv_ext1 = zsb + 1
          dz_ext0 = dz_ext1 = dz0 - 1 - 3 * SQUISH_CONSTANT_4D
          if (c1 & 0x03) == 0
            zsv_ext0 += 1
            dz_ext0 -= 1
          else
            zsv_ext1 += 1
            dz_ext1 -= 1
          end
        else
          zsv_ext0 = zsv_ext1 = zsb
          dz_ext0 = dz_ext1 = dz0 - 3 * SQUISH_CONSTANT_4D
        end

        if (c1 & 0x08) != 0
          wsv_ext0 = wsb + 1
          wsv_ext1 = wsb + 2
          dw_ext0 = dw0 - 1 - 3 * SQUISH_CONSTANT_4D
          dw_ext1 = dw0 - 2 - 3 * SQUISH_CONSTANT_4D
        else
          wsv_ext0 = wsv_ext1 = wsb
          dw_ext0 = dw_ext1 = dw0 - 3 * SQUISH_CONSTANT_4D
        end

        # One contribution is a _permutation of (1,1,1,-1) based on the smaller-sided po
        xsv_ext2 = xsb + 1
        ysv_ext2 = ysb + 1
        zsv_ext2 = zsb + 1
        wsv_ext2 = wsb + 1
        dx_ext2 = dx0 - 1 - 2 * SQUISH_CONSTANT_4D
        dy_ext2 = dy0 - 1 - 2 * SQUISH_CONSTANT_4D
        dz_ext2 = dz0 - 1 - 2 * SQUISH_CONSTANT_4D
        dw_ext2 = dw0 - 1 - 2 * SQUISH_CONSTANT_4D
        if (c2 & 0x01) == 0
          xsv_ext2 -= 2
          dx_ext2 += 2
        elsif (c2 & 0x02) == 0
          ysv_ext2 -= 2
          dy_ext2 += 2
        elsif (c2 & 0x04) == 0
          zsv_ext2 -= 2
          dz_ext2 += 2
        else
          wsv_ext2 -= 2
          dw_ext2 += 2
        end
      end

      # Contribution (1,1,1,0)
      dx4 = dx0 - 1 - 3 * SQUISH_CONSTANT_4D
      dy4 = dy0 - 1 - 3 * SQUISH_CONSTANT_4D
      dz4 = dz0 - 1 - 3 * SQUISH_CONSTANT_4D
      dw4 = dw0 - 3 * SQUISH_CONSTANT_4D
      attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4
      if attn4 > 0
        attn4 *= attn4
        value += attn4 * attn4 * extrapolate(xsb + 1, ysb + 1, zsb + 1, wsb + 0, dx4, dy4, dz4, dw4)
      end

      # Contribution (1,1,0,1)
      dx3 = dx4
      dy3 = dy4
      dz3 = dz0 - 3 * SQUISH_CONSTANT_4D
      dw3 = dw0 - 1 - 3 * SQUISH_CONSTANT_4D
      attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3
      if attn3 > 0
        attn3 *= attn3
        value += attn3 * attn3 * extrapolate(xsb + 1, ysb + 1, zsb + 0, wsb + 1, dx3, dy3, dz3, dw3)
      end

      # Contribution (1,0,1,1)
      dx2 = dx4
      dy2 = dy0 - 3 * SQUISH_CONSTANT_4D
      dz2 = dz4
      dw2 = dw3
      attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2
      if attn2 > 0
        attn2 *= attn2
        value += attn2 * attn2 * extrapolate(xsb + 1, ysb + 0, zsb + 1, wsb + 1, dx2, dy2, dz2, dw2)
      end

      # Contribution (0,1,1,1)
      dx1 = dx0 - 3 * SQUISH_CONSTANT_4D
      dz1 = dz4
      dy1 = dy4
      dw1 = dw3
      attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1
      if attn1 > 0
        attn1 *= attn1
        value += attn1 * attn1 * extrapolate(xsb + 0, ysb + 1, zsb + 1, wsb + 1, dx1, dy1, dz1, dw1)
      end

      # Contribution (1,1,0,0)
      dx5 = dx0 - 1 - 2 * SQUISH_CONSTANT_4D
      dy5 = dy0 - 1 - 2 * SQUISH_CONSTANT_4D
      dz5 = dz0 - 0 - 2 * SQUISH_CONSTANT_4D
      dw5 = dw0 - 0 - 2 * SQUISH_CONSTANT_4D
      attn5 = 2 - dx5 * dx5 - dy5 * dy5 - dz5 * dz5 - dw5 * dw5
      if attn5 > 0
        attn5 *= attn5
        value += attn5 * attn5 * extrapolate(xsb + 1, ysb + 1, zsb + 0, wsb + 0, dx5, dy5, dz5, dw5)
      end

      # Contribution (1,0,1,0)
      dx6 = dx0 - 1 - 2 * SQUISH_CONSTANT_4D
      dy6 = dy0 - 0 - 2 * SQUISH_CONSTANT_4D
      dz6 = dz0 - 1 - 2 * SQUISH_CONSTANT_4D
      dw6 = dw0 - 0 - 2 * SQUISH_CONSTANT_4D
      attn6 = 2 - dx6 * dx6 - dy6 * dy6 - dz6 * dz6 - dw6 * dw6
      if attn6 > 0
        attn6 *= attn6
        value += attn6 * attn6 * extrapolate(xsb + 1, ysb + 0, zsb + 1, wsb + 0, dx6, dy6, dz6, dw6)
      end

      # Contribution (1,0,0,1)
      dx7 = dx0 - 1 - 2 * SQUISH_CONSTANT_4D
      dy7 = dy0 - 0 - 2 * SQUISH_CONSTANT_4D
      dz7 = dz0 - 0 - 2 * SQUISH_CONSTANT_4D
      dw7 = dw0 - 1 - 2 * SQUISH_CONSTANT_4D
      attn7 = 2 - dx7 * dx7 - dy7 * dy7 - dz7 * dz7 - dw7 * dw7
      if attn7 > 0
        attn7 *= attn7
        value += attn7 * attn7 * extrapolate(xsb + 1, ysb + 0, zsb + 0, wsb + 1, dx7, dy7, dz7, dw7)
      end

      # Contribution (0,1,1,0)
      dx8 = dx0 - 0 - 2 * SQUISH_CONSTANT_4D
      dy8 = dy0 - 1 - 2 * SQUISH_CONSTANT_4D
      dz8 = dz0 - 1 - 2 * SQUISH_CONSTANT_4D
      dw8 = dw0 - 0 - 2 * SQUISH_CONSTANT_4D
      attn8 = 2 - dx8 * dx8 - dy8 * dy8 - dz8 * dz8 - dw8 * dw8
      if attn8 > 0
        attn8 *= attn8
        value += attn8 * attn8 * extrapolate(xsb + 0, ysb + 1, zsb + 1, wsb + 0, dx8, dy8, dz8, dw8)
      end

      # Contribution (0,1,0,1)
      dx9 = dx0 - 0 - 2 * SQUISH_CONSTANT_4D
      dy9 = dy0 - 1 - 2 * SQUISH_CONSTANT_4D
      dz9 = dz0 - 0 - 2 * SQUISH_CONSTANT_4D
      dw9 = dw0 - 1 - 2 * SQUISH_CONSTANT_4D
      attn9 = 2 - dx9 * dx9 - dy9 * dy9 - dz9 * dz9 - dw9 * dw9
      if attn9 > 0
        attn9 *= attn9
        value += attn9 * attn9 * extrapolate(xsb + 0, ysb + 1, zsb + 0, wsb + 1, dx9, dy9, dz9, dw9)
      end

      # Contribution (0,0,1,1)
      dx10 = dx0 - 0 - 2 * SQUISH_CONSTANT_4D
      dy10 = dy0 - 0 - 2 * SQUISH_CONSTANT_4D
      dz10 = dz0 - 1 - 2 * SQUISH_CONSTANT_4D
      dw10 = dw0 - 1 - 2 * SQUISH_CONSTANT_4D
      attn10 = 2 - dx10 * dx10 - dy10 * dy10 - dz10 * dz10 - dw10 * dw10
      if attn10 > 0
        attn10 *= attn10
        value += attn10 * attn10 * extrapolate(xsb + 0, ysb + 0, zsb + 1, wsb + 1, dx10, dy10, dz10, dw10)
      end
    end

    # First extra vertex
    attn_ext0 = 2 - dx_ext0 * dx_ext0 - dy_ext0 * dy_ext0 - dz_ext0 * dz_ext0 - dw_ext0 * dw_ext0
    if attn_ext0 > 0
      attn_ext0 *= attn_ext0
      value += attn_ext0 * attn_ext0 * extrapolate(xsv_ext0, ysv_ext0, zsv_ext0, wsv_ext0, dx_ext0, dy_ext0, dz_ext0, dw_ext0)
    end

    # Second extra vertex
    attn_ext1 = 2 - dx_ext1 * dx_ext1 - dy_ext1 * dy_ext1 - dz_ext1 * dz_ext1 - dw_ext1 * dw_ext1
    if attn_ext1 > 0
      attn_ext1 *= attn_ext1
      value += attn_ext1 * attn_ext1 * extrapolate(xsv_ext1, ysv_ext1, zsv_ext1, wsv_ext1, dx_ext1, dy_ext1, dz_ext1, dw_ext1)
    end

    # Third extra vertex
    attn_ext2 = 2 - dx_ext2 * dx_ext2 - dy_ext2 * dy_ext2 - dz_ext2 * dz_ext2 - dw_ext2 * dw_ext2
    if attn_ext2 > 0
      attn_ext2 *= attn_ext2
      value += attn_ext2 * attn_ext2 * extrapolate(xsv_ext2, ysv_ext2, zsv_ext2, wsv_ext2, dx_ext2, dy_ext2, dz_ext2, dw_ext2)
    end

    value / NORM_CONSTANT_4D
  end
end
