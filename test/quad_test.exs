#
#  Created by Boyd Multerer on 10/26/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#


defmodule Scenic.Math.QuadTest do
  use ExUnit.Case
  doctest Scenic.Math
  alias Scenic.Math.Quad

  @convex       {{100,300},{300,180},{400,310},{300,520}}
  @concave      {{100,300},{300,180},{400,310},{300,200}}
  @complex      {{100,300},{400,100},{400,300},{100,100}}

  #============================================================================
  # trunc
  test "classification identifies convex quads" do
    assert Quad.classification( @convex ) == :convex
  end
  
  test "classification identifies concave quads" do
    assert Quad.classification( @concave ) == :concave
  end
  
  test "classification identifies complex quads" do
    assert Quad.classification( @complex ) == :complex
  end
  
end