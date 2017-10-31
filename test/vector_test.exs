#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.VectorTest do
  use ExUnit.Case
  doctest Scenic.Math
  alias Scenic.Math.MatrixBin, as: Matrix
  alias Scenic.Math.Vector


  #----------------------------------------------------------------------------
  # build
  test "build(x,y) works" do
    assert Vector.build( 2.0, 3.0 ) == {2.0, 3.0}
  end
  
  test "build(x,y,z) works" do
    assert Vector.build( 2.0, 3.0, 4.0 ) == {2.0, 3.0, 4.0}
  end

  test "build(x,y,zw) works" do
    assert Vector.build( 2.0, 3.0, 4.0, 5.0 ) == {2.0, 3.0, 4.0, 5.0}
  end

  #----------------------------------------------------------------------------
  # trunc
  test "trunc(x,y) works" do
    assert Vector.trunc({1.1, 2.8}) == {1, 2}
  end
  test "trunc(x,y,z) works" do
    assert Vector.trunc({1.1,2.8,3.2}) == {1, 2, 3}
  end

  #----------------------------------------------------------------------------
  # round  
  test "round(x,y) works" do
    assert Vector.round({1.1, 2.8}) == {1, 3}
  end
  test "round(x,y,z) works" do
    assert Vector.round({1.1,2.8,3.2}) == {1, 3, 3}
  end

  #--------------------------------------------------------
  # length

  test "length xy works" do
    assert Vector.length( {3.0,4.0} ) == 5.0
  end
  test "length xyz works" do
    assert Vector.length( {5.0, 3.0,4.0} ) == :math.sqrt(50)
  end
  test "length xyzw works" do
    assert Vector.length( {2.0,3.0,4.0,5.0} ) == :math.sqrt(54)
  end

  #--------------------------------------------------------
  # length_squared
  test "length_squared xy works" do
    assert Vector.length_squared( {3.0,4.0} ) == 25.0
  end
  test "length_squared xyz works" do
    assert Vector.length_squared( {5.0, 3.0,4.0} ) == 50.0
  end
  test "length_squared xyzw works" do
    assert Vector.length_squared( {2.0,3.0,4.0,5.0} ) == 54.0
  end

  #--------------------------------------------------------
  # project
  test "project a 2d vector works" do
    mx = Matrix.build_translation({5,7})
    assert Vector.project( {10,20}, mx ) == {15, 27}
  end

  test "project a 3d vector works" do
    mx = Matrix.build_translation({5,7,11})
    assert Vector.project( {10,20,30}, mx ) == {15, 27,41}
  end

end