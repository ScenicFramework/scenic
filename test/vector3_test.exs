#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.Vector3Test do
  use ExUnit.Case
  doctest Scenic.Math
  alias Scenic.Math.Vector3
  alias Scenic.Math.MatrixBin, as: Matrix

  @projection_mx  Matrix.build_translation({5,7,11})

  #----------------------------------------------------------------------------
  # common constants
  test "zero constant" do
    assert Vector3.zero() == {0.0, 0.0, 0.0}
  end

  test "one constant" do
    assert Vector3.one() == {1.0, 1.0, 1.0}
  end

  test "unity_x constant" do
    assert Vector3.unity_x() == {1.0, 0.0, 0.0}
  end

  test "unity_y constant" do
    assert Vector3.unity_y() == {0.0, 1.0, 0.0}
  end

  test "unity_z constant" do
    assert Vector3.unity_z() == {0.0, 0.0, 1.0}
  end

  test "up constant" do
    assert Vector3.up() == {0.0, 1.0, 0.0}
  end

  test "down constant" do
    assert Vector3.down() == {0.0, -1.0, 0.0}
  end

  test "left constant" do
    assert Vector3.left() == {-1.0, 0.0, 0.0}
  end

  test "right constant" do
    assert Vector3.right() == {1.0, 0.0, 0.0}
  end

  test "forward constant" do
    assert Vector3.forward() == {0.0, 0.0, -1.0}
  end

  test "backward constant" do
    assert Vector3.backward() == {0.0, 0.0, 1.0}
  end


  #----------------------------------------------------------------------------
  # build( x, y, z )
  test "build works" do
    assert Vector3.build( 2.0, 3.0, 4.0 ) == {2.0, 3.0, 4.0}
  end

  #--------------------------------------------------------
  # length
  test "length_squared works" do
    assert Vector3.length_squared( {5.0, 3.0,4.0} ) == 50.0
  end  

  test "length works" do
    assert Vector3.length( {5.0, 3.0,4.0} ) == :math.sqrt(50)
  end

  #----------------------------------------------------------------------------
  # distance_squared( a, b )
  # http://snipd.net/2d-and-3d-vector-normalization-and-angle-calculation-in-c
  test "distance_squared" do
    assert Vector3.distance_squared( {5.0,3.0,4.0}, {9.0,7.0,8.0} ) == 48.0
  end

  #----------------------------------------------------------------------------
  # distance( a, b )
  #http://www.calculatorsoup.com/calculators/geometry-plane/distance-two-points.php
  test "distance" do
    assert Vector3.distance( {5.0,3.0,4.0}, {9.0,7.0,8.0} ) == :math.sqrt(48)
  end

  #----------------------------------------------------------------------------
  # add and substract
  test "add vectors" do
    assert Vector3.add( {2.0, 5.0, 3.0}, {8.0, 3.0, 1.0} ) == {10.0, 8.0, 4.0}
  end

  test "sub vectors" do
    assert Vector3.sub( {10.0, 8.0, 3.0}, {8.0, 3.0, 1.0} ) == {2.0, 5.0, 2.0}
  end

  #----------------------------------------------------------------------------
  # multiply vector by scalar
  # mul( a, s )
  test "mul by scalar" do
    assert Vector3.mul( {10.0, 8.0, 3.0}, 2.0 ) == {20.0, 16.0, 6.0}
  end

  #----------------------------------------------------------------------------
  # dot( a, b )
  # https://www.mathsisfun.com/algebra/vectors-dot-product.html
  test "dot product" do
    assert Vector3.dot( {9.0, 2.0, 7.0}, {4.0, 8.0, 10.0} ) == 122.0
  end

  #----------------------------------------------------------------------------
  # cross( a, b )
  # https://www.mathsisfun.com/algebra/vectors-dot-product.html
  test "cross product" do
    assert Vector3.cross( {2.0, 3.0, 4.0}, {5.0, 6.0, 7.0} ) == {-3.0, 6.0, -3.0}
  end

  #----------------------------------------------------------------------------
  # normalize( a )
  # https://www.wolframalpha.com/input/?i=normalize+%7B3,4,6%7D
  test "normalize" do
    assert Vector3.normalize( {3.0,4.0,6.0} ) == {
      3 / :math.sqrt(61.0),
      4 / :math.sqrt(61.0),
      6 / :math.sqrt(61.0),
    }
  end

  #----------------------------------------------------------------------------
  # min( a, b )
  # max( a, b )
  test "min" do
    assert Vector3.min( {9.0,13.0,7.0}, {12.0,11.0,8.0} ) == {9.0,11.0,7.0}
  end
  test "max" do
    assert Vector3.max( {9.0,13.0,7.0}, {12.0,11.0,8.0} ) == {12.0,13.0,8.0}
  end

  #----------------------------------------------------------------------------
  # clamp( vector, min, max )
  test "clamp leaves vector alone if between" do
    assert Vector3.clamp( {4.0,5.0,6.0}, {2.0,3.0,4.0}, {6.0,7.0,8.0} ) == {4.0,5.0,6.0}
  end
  test "clamp returns min if all below" do
    assert Vector3.clamp( {1.0,2.0,3.0}, {2.0,3.0,4.0}, {6.0,7.0,8.0} ) == {2.0,3.0,4.0}
  end
  test "clamp returns max if all above" do
    assert Vector3.clamp( {14.0,15.0,16.0}, {2.0,3.0,4.0}, {6.0,7.0,8.0} ) == {6.0,7.0,8.0}
  end
  test "clamp returns mixed min max and v" do
    assert Vector3.clamp( {1.0,5.0,6.0},  {2.0,3.0,4.0}, {6.0,7.0,8.0} )  == {2.0,5.0,6.0}
    assert Vector3.clamp( {14.0,5.0,6.0}, {2.0,3.0,4.0}, {6.0,7.0,8.0} )  == {6.0,5.0,6.0}

    assert Vector3.clamp( {4.0,1.0,6.0},  {2.0,3.0,4.0}, {6.0,7.0,8.0} )  == {4.0,3.0,6.0}
    assert Vector3.clamp( {4.0,15.0,6.0}, {2.0,3.0,4.0}, {6.0,7.0,8.0} )  == {4.0,7.0,6.0}

    assert Vector3.clamp( {4.0,5.0,1.0}, {2.0,3.0,4.0}, {6.0,7.0,8.0} )   == {4.0,5.0,4.0}
    assert Vector3.clamp( {4.0,5.0,16.0}, {2.0,3.0,4.0}, {6.0,7.0,8.0} )  == {4.0,5.0,8.0}
  end


  #----------------------------------------------------------------------------
  # in_bounds( vector, bounds )
  test "in_bounds/2 returns true if the vector is within the +-bounds" do
    assert Vector3.in_bounds( {3.0,4.0,5.0}, {5.0,6.0,7.0} )    == true
    assert Vector3.in_bounds( {-3.0,4.0,5.0}, {5.0,6.0,7.0} )   == true
    assert Vector3.in_bounds( {3.0,-4.0,5.0}, {5.0,6.0,7.0} )   == true
    assert Vector3.in_bounds( {3.0,4.0,-5.0}, {5.0,6.0,7.0} )   == true
    assert Vector3.in_bounds( {-3.0,-4.0,-5.0}, {5.0,6.0,7.0} ) == true
  end
  test "in_bounds/2 returns false if vector is below -bounds" do
    assert Vector3.in_bounds( {-5.1,4.0,5.0}, {5.0,6.0,7.0} )   == false
    assert Vector3.in_bounds( {3.0,-6.1,5.0}, {5.0,6.0,7.0} )   == false
    assert Vector3.in_bounds( {3.0,4.0,-7.1}, {5.0,6.0,7.0} )   == false
    assert Vector3.in_bounds( {-5.1,-6.1,-7.1}, {5.0,6.0,7.0} ) == false
  end
  test "in_bounds/2 returns false if vector is above +bounds" do
    assert Vector3.in_bounds( {5.1,4.0,5.0}, {5.0,6.0,7.0} )    == false
    assert Vector3.in_bounds( {3.0,6.1,5.0}, {5.0,6.0,7.0} )    == false
    assert Vector3.in_bounds( {3.0,4.0,7.1}, {5.0,6.0,7.0} )    == false
    assert Vector3.in_bounds( {5.1,6.1,7.1}, {5.0,6.0,7.0} )    == false
  end

  #----------------------------------------------------------------------------
  # in_bounds( vector, min_bound, max_bound )
  test "in_bounds/3 returns true if the (positive) vector is within the min/max bounds" do
    assert Vector3.in_bounds( {3.0,4.0,5.0}, {1.0,2.0,3.0} , {5.0,6.0,7.0} ) == true
  end
  test "in_bounds/3 returns false if vector is below min_bound" do
    assert Vector3.in_bounds( {0.9,4.0,5.0}, {1.0,2.0,3.0} , {5.0,6.0,7.0} ) == false
    assert Vector3.in_bounds( {3.0,1.9,5.0}, {1.0,2.0,3.0} , {5.0,6.0,7.0} ) == false
    assert Vector3.in_bounds( {3.0,4.0,2.9}, {1.0,2.0,3.0} , {5.0,6.0,7.0} ) == false
    assert Vector3.in_bounds( {0.0,1.9,2.9}, {1.0,2.0,3.0} , {5.0,6.0,7.0} ) == false
  end
  test "in_bounds/3 returns false if vector is above max_bound" do
    assert Vector3.in_bounds( {5.1,4.0,5.0}, {1.0,2.0,3.0} , {5.0,6.0,7.0} ) == false
    assert Vector3.in_bounds( {3.0,6.1,5.0}, {1.0,2.0,3.0} , {5.0,6.0,7.0} ) == false
    assert Vector3.in_bounds( {3.0,4.0,7.1}, {1.0,2.0,3.0} , {5.0,6.0,7.0} ) == false
    assert Vector3.in_bounds( {5.1,6.1,7.1}, {1.0,2.0,3.0} , {5.0,6.0,7.0} ) == false
  end


  #----------------------------------------------------------------------------
  # lerp( a, b, t )
  test "lerp" do
    assert Vector3.lerp( {9.0,13.0,7.0}, {12.0,11.0,8.0}, 0.5 ) == {10.5,12.0,7.5}
  end

  #----------------------------------------------------------------------------
  # nlerp( a, b, t )
  test "nlerp" do
    assert Vector3.nlerp( {9.0,13.0,7.0}, {12.0,11.0,8.0}, 0.5 ) ==
      {0.595879571531124, 0.681005224606999, 0.4256282653793743}
  end


  #----------------------------------------------------------------------------
  # project( {x,y,z}, matrix )
  test "project works with a vector tuple" do
    assert Vector3.project( {10,20,30}, @projection_mx ) == {15,27,41}
  end

  test "project works with a packed binary" do
    vectors_in = <<
      10  :: float-size(32)-native,
      20  :: float-size(32)-native,
      30  :: float-size(32)-native,
      100 :: float-size(32)-native,
      200 :: float-size(32)-native,
      300 :: float-size(32)-native,
    >>
    assert Vector3.project( vectors_in, @projection_mx ) == <<
      15  :: float-size(32)-native,
      27  :: float-size(32)-native,
      41  :: float-size(32)-native,
      105 :: float-size(32)-native,
      207 :: float-size(32)-native,
      311 :: float-size(32)-native,
    >>
  end


end


























