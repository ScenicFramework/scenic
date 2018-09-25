#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.Vector2Test do
  use ExUnit.Case
  doctest Scenic.Math
  doctest Scenic.Math.Line
  doctest Scenic.Math.Vector2
  alias Scenic.Math.Vector2
  alias Scenic.Math.Matrix

  @projection_mx Matrix.build_translation({5, 7})

  # ----------------------------------------------------------------------------
  # common constants
  test "zero constant" do
    assert Vector2.zero() == {0.0, 0.0}
  end

  test "one constant" do
    assert Vector2.one() == {1.0, 1.0}
  end

  test "unity_x constant" do
    assert Vector2.unity_x() == {1.0, 0.0}
  end

  test "unity_y constant" do
    assert Vector2.unity_y() == {0.0, 1.0}
  end

  test "up constant" do
    assert Vector2.up() == {0.0, 1.0}
  end

  test "down constant" do
    assert Vector2.down() == {0.0, -1.0}
  end

  test "left constant" do
    assert Vector2.left() == {-1.0, 0.0}
  end

  test "right constant" do
    assert Vector2.right() == {1.0, 0.0}
  end

  # ----------------------------------------------------------------------------
  # # build( x, y )
  # test "build works" do
  #   assert Vector2.build(2.0, 3.0) == {2.0, 3.0}
  # end

  # --------------------------------------------------------
  # length
  test "length_squared works" do
    assert Vector2.length_squared({3.0, 4.0}) == 25.0
  end

  test "length works" do
    assert Vector2.length({3.0, 4.0}) == 5.0
  end

  # ----------------------------------------------------------------------------
  # distance_squared( a, b )
  # http://snipd.net/2d-and-3d-vector-normalization-and-angle-calculation-in-c
  test "distance_squared" do
    assert Vector2.distance_squared({9.0, 13.0}, {12.0, 17.0}) == 25.0
  end

  # ----------------------------------------------------------------------------
  # distance( a, b )
  # http://www.calculatorsoup.com/calculators/geometry-plane/distance-two-points.php
  test "distance" do
    assert Vector2.distance({9.0, 13.0}, {12.0, 17.0}) == 5.0
  end

  # ----------------------------------------------------------------------------
  # add and substract
  test "add vectors" do
    assert Vector2.add({2.0, 5.0}, {8.0, 3.0}) == {10.0, 8.0}
  end

  test "sub vectors" do
    assert Vector2.sub({10.0, 8.0}, {8.0, 3.0}) == {2.0, 5.0}
  end

  # ----------------------------------------------------------------------------
  # multiply vector by scalar
  # mul( a, s )
  test "mul by scalar" do
    assert Vector2.mul({10.0, 8.0}, 2.0) == {20.0, 16.0}
  end

  # ----------------------------------------------------------------------------
  # dot( a, b )
  # https://www.mathsisfun.com/algebra/vectors-dot-product.html
  test "dot product" do
    assert Vector2.dot({2.0, 5.0}, {8.0, 3.0}) == 31.0
  end

  # ----------------------------------------------------------------------------
  # cross( a, b )
  # https://www.mathsisfun.com/algebra/vectors-dot-product.html
  test "cross product" do
    assert Vector2.cross({2.0, 5.0}, {8.0, 3.0}) == -34.0
  end

  # ----------------------------------------------------------------------------
  # normalize( a )
  # http://snipd.net/2d-and-3d-vector-normalization-and-angle-calculation-in-c
  test "normalize" do
    assert Vector2.normalize({3.0, 4.0}) == {0.6, 0.8}
  end

  # ----------------------------------------------------------------------------
  # min( a, b )
  # max( a, b )
  test "min" do
    assert Vector2.min({9.0, 13.0}, {12.0, 11.0}) == {9.0, 11.0}
  end

  test "max" do
    assert Vector2.max({9.0, 13.0}, {12.0, 11.0}) == {12.0, 13.0}
  end

  # ----------------------------------------------------------------------------
  # clamp( vector, min, max )
  test "clamp leaves vector alone if between" do
    assert Vector2.clamp({4.0, 5.0}, {2.0, 3.0}, {6.0, 7.0}) == {4.0, 5.0}
  end

  test "clamp returns min if all below" do
    assert Vector2.clamp({1.0, 2.0}, {2.0, 3.0}, {6.0, 7.0}) == {2.0, 3.0}
  end

  test "clamp returns max if all above" do
    assert Vector2.clamp({14.0, 15.0}, {2.0, 3.0}, {6.0, 7.0}) == {6.0, 7.0}
  end

  test "clamp returns mixed min max and v" do
    assert Vector2.clamp({1.0, 5.0}, {2.0, 3.0}, {6.0, 7.0}) == {2.0, 5.0}
    assert Vector2.clamp({11.0, 5.0}, {2.0, 3.0}, {6.0, 7.0}) == {6.0, 5.0}
    assert Vector2.clamp({4.0, 1.0}, {2.0, 3.0}, {6.0, 7.0}) == {4.0, 3.0}
    assert Vector2.clamp({4.0, 15.0}, {2.0, 3.0}, {6.0, 7.0}) == {4.0, 7.0}
  end

  # ----------------------------------------------------------------------------
  # in_bounds?( vector, bounds )
  test "in_bounds?/2 returns true if the vector is within the +-bounds" do
    assert Vector2.in_bounds?({3.0, 4.0}, {5.0, 6.0}) == true
    assert Vector2.in_bounds?({-3.0, 4.0}, {5.0, 6.0}) == true
    assert Vector2.in_bounds?({3.0, -4.0}, {5.0, 6.0}) == true
    assert Vector2.in_bounds?({-3.0, -4.0}, {5.0, 6.0}) == true
  end

  test "in_bounds?/2 returns false if vector is below -bounds" do
    assert Vector2.in_bounds?({-5.1, 4.0}, {5.0, 6.0}) == false
    assert Vector2.in_bounds?({3.0, -6.1}, {5.0, 6.0}) == false
    assert Vector2.in_bounds?({-5.1, -6.1}, {5.0, 6.0}) == false
  end

  test "in_bounds?/2 returns false if vector is above +bounds" do
    assert Vector2.in_bounds?({5.1, 4.0}, {5.0, 6.0}) == false
    assert Vector2.in_bounds?({3.0, 6.1}, {5.0, 6.0}) == false
    assert Vector2.in_bounds?({5.1, 6.1}, {5.0, 6.0}) == false
  end

  # ----------------------------------------------------------------------------
  # in_bounds?( vector, min_bound, max_bound )
  test "in_bounds?/3 returns true if the (positive) vector is within the min/max bounds" do
    assert Vector2.in_bounds?({3.0, 4.0}, {1.0, 2.0}, {5.0, 6.0}) == true
  end

  test "in_bounds?/3 returns false if vector is below min_bound" do
    assert Vector2.in_bounds?({0.9, 4.0}, {1.0, 2.0}, {5.0, 6.0}) == false
    assert Vector2.in_bounds?({3.0, 1.9}, {1.0, 2.0}, {5.0, 6.0}) == false
    assert Vector2.in_bounds?({0.0, 1.9}, {1.0, 2.0}, {5.0, 6.0}) == false
  end

  test "in_bounds?/3 returns false if vector is above max_bound" do
    assert Vector2.in_bounds?({5.1, 4.0}, {1.0, 2.0}, {5.0, 6.0}) == false
    assert Vector2.in_bounds?({3.0, 6.1}, {1.0, 2.0}, {5.0, 6.0}) == false
    assert Vector2.in_bounds?({5.1, 6.1}, {1.0, 2.0}, {5.0, 6.0}) == false
  end

  # ----------------------------------------------------------------------------
  # lerp( a, b, t )
  test "lerp" do
    assert Vector2.lerp({9.0, 13.0}, {12.0, 11.0}, 0.5) == {10.5, 12.0}
    assert Vector2.lerp({2.0, 5.0}, {8.0, 11.0}, 0.5) == {5.0, 8.0}
  end

  # ----------------------------------------------------------------------------
  # nlerp( a, b, t )
  test "nlerp" do
    assert Vector2.nlerp({2.0, 3.0}, {4.0, 5.0}, 0.5) == {0.6, 0.8}
  end

  # ----------------------------------------------------------------------------
  # project( {x,y}, matrix )
  test "project works with a vector tuple" do
    assert Vector2.project({10, 20}, @projection_mx) == {15, 27}
  end

  test "project works with a packed binary" do
    vectors_in = <<
      10::float-size(32)-native,
      20::float-size(32)-native,
      100::float-size(32)-native,
      200::float-size(32)-native
    >>

    assert Vector2.project(vectors_in, @projection_mx) == <<
             15::float-size(32)-native,
             27::float-size(32)-native,
             105::float-size(32)-native,
             207::float-size(32)-native
           >>
  end
end
