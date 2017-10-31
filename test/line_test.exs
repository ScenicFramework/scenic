#
#  Created by Boyd Multerer on 10/26/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#


defmodule Scenic.Math.LineTest do
  use ExUnit.Case
  doctest Scenic.Math
  alias Scenic.Math.Line

  @line_0   {{0,0},{10,10}}
  @line_1   {{0,10},{10,0}}
  @line_h   {{10,10}, {100,10}}
  @line_v   {{10,10}, {10,100}}

  #----------------------------------------------------------------------------
  # trunc
  test "trunc(x,y) works" do
    assert Line.trunc({{1.1, 2.8}, {2.1, 3.3}}) ==
      {{1, 2},{2, 3}}
  end
  test "trunc(x,y,z) works" do
    assert Line.trunc({{1.1,2.8,3.2}, {2.1, 3.8,4.7}}) ==
      {{1, 2, 3}, {2, 3, 4}}
  end

  #----------------------------------------------------------------------------
  # round  
  test "round(x,y) works" do
    assert Line.round({{1.1, 2.8}, {2.1, 3.3}}) ==
      {{1, 3},{2, 3}}
  end
  test "round(x,y,z) works" do
    assert Line.round({{1.1,2.8,3.2}, {2.1, 3.8,4.7}}) ==
      {{1, 3, 3}, {2, 4, 5}}
  end

  #----------------------------------------------------------------------------
  # parallel
  test "parallel makes a parallel line" do
    assert Line.parallel(@line_h, 3)  == {{10,7}, {100,7}}
    assert Line.parallel(@line_h, -3) == {{10,13}, {100,13}}

    assert Line.parallel(@line_v, 3)  == {{13,10}, {13,100}}
    assert Line.parallel(@line_v, -3) == {{7,10}, {7,100}}
  end

  #----------------------------------------------------------------------------
  # intersection
  test "intersection finds the intersection of two lines" do
    assert Line.intersection(@line_0, @line_1) == {5.0, 5.0}
  end

end