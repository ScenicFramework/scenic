#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.Vector4Test do
  use ExUnit.Case
  doctest Scenic.Math
  alias Scenic.Math.Vector4

  # ----------------------------------------------------------------------------
  # common constants
  test "zero constant" do
    assert Vector4.zero() == {0.0, 0.0, 0.0, 0.0}
  end

  test "one constant" do
    assert Vector4.one() == {1.0, 1.0, 1.0, 1.0}
  end

  test "unity_x constant" do
    assert Vector4.unity_x() == {1.0, 0.0, 0.0, 0.0}
  end

  test "unity_y constant" do
    assert Vector4.unity_y() == {0.0, 1.0, 0.0, 0.0}
  end

  test "unity_z constant" do
    assert Vector4.unity_z() == {0.0, 0.0, 1.0, 0.0}
  end

  test "unity_w constant" do
    assert Vector4.unity_w() == {0.0, 0.0, 0.0, 1.0}
  end

  # ----------------------------------------------------------------------------
  # build( x, y, z )
  test "build works" do
    assert Vector4.build(2.0, 3.0, 4.0, 5.0) == {2.0, 3.0, 4.0, 5.0}
  end

  # --------------------------------------------------------
  # length
  test "length_squared works" do
    assert Vector4.length_squared({2.0, 3.0, 4.0, 5.0}) == 54.0
  end

  test "length works" do
    assert Vector4.length({2.0, 3.0, 4.0, 5.0}) == :math.sqrt(54)
  end

  # ----------------------------------------------------------------------------
  # distance_squared( a, b )
  # http://snipd.net/2d-and-3d-vector-normalization-and-angle-calculation-in-c
  test "distance_squared" do
    assert Vector4.distance_squared({2.0, 3.0, 4.0, 5.0}, {10.0, 9.0, 8.0, 7.0}) == 120.0
  end

  # ----------------------------------------------------------------------------
  # distance( a, b )
  # http://www.calculatorsoup.com/calculators/geometry-plane/distance-two-points.php
  test "distance" do
    assert Vector4.distance({2.0, 3.0, 4.0, 5.0}, {10.0, 9.0, 8.0, 7.0}) == :math.sqrt(120.0)
  end

  # ----------------------------------------------------------------------------
  # add and substract
  test "add vectors" do
    assert Vector4.add({2.0, 3.0, 4.0, 5.0}, {8.0, 3.0, 1.0, 2.0}) == {10.0, 6.0, 5.0, 7.0}
  end

  test "sub vectors" do
    assert Vector4.sub({10.0, 6.0, 5.0, 7.0}, {8.0, 3.0, 1.0, 2.0}) == {2.0, 3.0, 4.0, 5.0}
  end

  # ----------------------------------------------------------------------------
  # multiply vector by scalar
  # mul( a, s )
  test "mul by scalar" do
    assert Vector4.mul({2.0, 3.0, 4.0, 5.0}, 2.0) == {4.0, 6.0, 8.0, 10.0}
  end

  # ----------------------------------------------------------------------------
  # dot( a, b )
  # https://www.mathsisfun.com/algebra/vectors-dot-product.html
  test "dot product" do
    assert Vector4.dot({9.0, 2.0, 7.0, 3.0}, {4.0, 8.0, 10.0, 5.0}) == 137.0
  end

  # ----------------------------------------------------------------------------
  # normalize( a )
  # https://www.wolframalpha.com/input/?i=normalize+%7B3,4,6,8%7D
  test "normalize" do
    denom = 5 * :math.sqrt(5)

    assert Vector4.normalize({3.0, 4.0, 6.0, 8.0}) == {
             3 / denom,
             4 / denom,
             6 / denom,
             8 / denom
           }
  end

  # ----------------------------------------------------------------------------
  # min( a, b )
  # max( a, b )
  test "min" do
    assert Vector4.min({9.0, 13.0, 7.0, 9.0}, {12.0, 11.0, 8.0, 3.0}) == {9.0, 11.0, 7.0, 3.0}
  end

  test "max" do
    assert Vector4.max({9.0, 13.0, 7.0, 9.0}, {12.0, 11.0, 8.0, 3.0}) == {12.0, 13.0, 8.0, 9.0}
  end

  # ----------------------------------------------------------------------------
  # clamp( vector, min, max )
  test "clamp leaves vector alone if between" do
    assert Vector4.clamp({4.0, 5.0, 6.0, 7.0}, {2.0, 3.0, 4.0, 5.0}, {6.0, 7.0, 8.0, 9.0}) ==
             {4.0, 5.0, 6.0, 7.0}
  end

  test "clamp returns min if all below" do
    assert Vector4.clamp({1.0, 2.0, 3.0, 4.0}, {2.0, 3.0, 4.0, 5.0}, {6.0, 7.0, 8.0, 9.0}) ==
             {2.0, 3.0, 4.0, 5.0}
  end

  test "clamp returns max if all above" do
    assert Vector4.clamp({14.0, 15.0, 16.0, 17.0}, {2.0, 3.0, 4.0, 5.0}, {6.0, 7.0, 8.0, 9.0}) ==
             {6.0, 7.0, 8.0, 9.0}
  end

  test "clamp returns mixed min max and v" do
    assert Vector4.clamp({1.0, 5.0, 6.0, 7.0}, {2.0, 3.0, 4.0, 5.0}, {6.0, 7.0, 8.0, 9.0}) ==
             {2.0, 5.0, 6.0, 7.0}

    assert Vector4.clamp({14.0, 5.0, 6.0, 7.0}, {2.0, 3.0, 4.0, 5.0}, {6.0, 7.0, 8.0, 9.0}) ==
             {6.0, 5.0, 6.0, 7.0}

    assert Vector4.clamp({4.0, 1.0, 6.0, 7.0}, {2.0, 3.0, 4.0, 5.0}, {6.0, 7.0, 8.0, 9.0}) ==
             {4.0, 3.0, 6.0, 7.0}

    assert Vector4.clamp({4.0, 15.0, 6.0, 7.0}, {2.0, 3.0, 4.0, 5.0}, {6.0, 7.0, 8.0, 9.0}) ==
             {4.0, 7.0, 6.0, 7.0}

    assert Vector4.clamp({4.0, 5.0, 1.0, 7.0}, {2.0, 3.0, 4.0, 5.0}, {6.0, 7.0, 8.0, 9.0}) ==
             {4.0, 5.0, 4.0, 7.0}

    assert Vector4.clamp({4.0, 5.0, 16.0, 7.0}, {2.0, 3.0, 4.0, 5.0}, {6.0, 7.0, 8.0, 9.0}) ==
             {4.0, 5.0, 8.0, 7.0}

    assert Vector4.clamp({4.0, 5.0, 6.0, 1.0}, {2.0, 3.0, 4.0, 5.0}, {6.0, 7.0, 8.0, 9.0}) ==
             {4.0, 5.0, 6.0, 5.0}

    assert Vector4.clamp({4.0, 5.0, 6.0, 17.0}, {2.0, 3.0, 4.0, 5.0}, {6.0, 7.0, 8.0, 9.0}) ==
             {4.0, 5.0, 6.0, 9.0}
  end

  # ----------------------------------------------------------------------------
  # in_bounds( vector, bounds )
  test "in_bounds/2 returns true if the vector is within the +-bounds" do
    assert Vector4.in_bounds({3.0, 4.0, 5.0, 6.0}, {5.0, 6.0, 7.0, 8.0}) == true
    assert Vector4.in_bounds({-3.0, 4.0, 5.0, 6.0}, {5.0, 6.0, 7.0, 8.0}) == true
    assert Vector4.in_bounds({3.0, -4.0, 5.0, 6.0}, {5.0, 6.0, 7.0, 8.0}) == true
    assert Vector4.in_bounds({3.0, 4.0, -5.0, 6.0}, {5.0, 6.0, 7.0, 8.0}) == true
    assert Vector4.in_bounds({3.0, 4.0, 5.0, -6.0}, {5.0, 6.0, 7.0, 8.0}) == true
    assert Vector4.in_bounds({-3.0, -4.0, -5.0, -6.0}, {5.0, 6.0, 7.0, 8.0}) == true
  end

  test "in_bounds/2 returns false if vector is below -bounds" do
    assert Vector4.in_bounds({-5.1, 4.0, 5.0, 6.0}, {5.0, 6.0, 7.0, 8.0}) == false
    assert Vector4.in_bounds({3.0, -6.1, 5.0, 6.0}, {5.0, 6.0, 7.0, 8.0}) == false
    assert Vector4.in_bounds({3.0, 4.0, -7.1, 6.0}, {5.0, 6.0, 7.0, 8.0}) == false
    assert Vector4.in_bounds({3.0, 4.0, 5.0, -8.1}, {5.0, 6.0, 7.0, 8.0}) == false
    assert Vector4.in_bounds({-5.1, -6.1, -7.1, -8.1}, {5.0, 6.0, 7.0, 8.0}) == false
  end

  test "in_bounds/2 returns false if vector is above +bounds" do
    assert Vector4.in_bounds({5.1, 4.0, 5.0, 6.0}, {5.0, 6.0, 7.0, 8.0}) == false
    assert Vector4.in_bounds({3.0, 6.1, 5.0, 6.0}, {5.0, 6.0, 7.0, 8.0}) == false
    assert Vector4.in_bounds({3.0, 4.0, 7.1, 6.0}, {5.0, 6.0, 7.0, 8.0}) == false
    assert Vector4.in_bounds({3.0, 4.0, 5.0, 8.1}, {5.0, 6.0, 7.0, 8.0}) == false
    assert Vector4.in_bounds({5.1, 6.1, 7.1, 8.1}, {5.0, 6.0, 7.0, 8.0}) == false
  end

  # ----------------------------------------------------------------------------
  # in_bounds( vector, min_bound, max_bound )
  test "in_bounds/3 returns true if the (positive) vector is within the min/max bounds" do
    assert Vector4.in_bounds({3.0, 4.0, 5.0, 6.0}, {1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}) ==
             true
  end

  test "in_bounds/3 returns false if vector is below min_bound" do
    assert Vector4.in_bounds({0.9, 4.0, 5.0, 6.0}, {1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}) ==
             false

    assert Vector4.in_bounds({3.0, 1.9, 5.0, 6.0}, {1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}) ==
             false

    assert Vector4.in_bounds({3.0, 4.0, 2.9, 6.0}, {1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}) ==
             false

    assert Vector4.in_bounds({3.0, 4.0, 5.0, 3.9}, {1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}) ==
             false

    assert Vector4.in_bounds({0.0, 1.9, 2.9, 3.9}, {1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}) ==
             false
  end

  test "in_bounds/3 returns false if vector is above max_bound" do
    assert Vector4.in_bounds({5.1, 4.0, 5.0, 6.0}, {1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}) ==
             false

    assert Vector4.in_bounds({3.0, 6.1, 5.0, 6.0}, {1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}) ==
             false

    assert Vector4.in_bounds({3.0, 4.0, 7.1, 6.0}, {1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}) ==
             false

    assert Vector4.in_bounds({3.0, 4.0, 5.0, 8.1}, {1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}) ==
             false

    assert Vector4.in_bounds({5.1, 6.1, 7.1, 8.1}, {1.0, 2.0, 3.0, 4.0}, {5.0, 6.0, 7.0, 8.0}) ==
             false
  end

  # ----------------------------------------------------------------------------
  # lerp( a, b, t )
  test "lerp" do
    assert Vector4.lerp({9.0, 13.0, 7.0, 2.0}, {12.0, 11.0, 8.0, 6.0}, 0.5) ==
             {10.5, 12.0, 7.5, 4.0}
  end

  # ----------------------------------------------------------------------------
  # nlerp( a, b, t )
  test "nlerp" do
    assert Vector4.nlerp({9.0, 13.0, 7.0, 2.0}, {12.0, 11.0, 8.0, 6.0}, 0.5) ==
             {0.5810957595581098, 0.6641094394949826, 0.41506839968436415, 0.2213698131649942}
  end
end
