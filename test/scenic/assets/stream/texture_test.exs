#
#  Created by Boyd Multerer on 2021-04-19
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Stream.TextureTest do
  use ExUnit.Case, async: true
  doctest Scenic.Assets.Stream.Texture

  alias Scenic.Color
  alias Scenic.Assets.Stream.Texture

  @width 11
  @height 13

  @texture :texture
  @mutable :mutable_texture


  #--------------------------------------------------------
  test "build :g works" do
    {@mutable, {w,h,:g}, p} = Texture.build( :g, @width, @height )
    assert w == @width
    assert h == @height
    assert byte_size(p) == @width * @height
  end

  test "build :ga works" do
    {@mutable, {w,h,:ga}, p} = Texture.build( :ga, @width, @height )
    assert w == @width
    assert h == @height
    assert byte_size(p) == @width * @height * 2
  end

  test "build :rgb works" do
    {@mutable, {w,h,:rgb}, p} = Texture.build( :rgb, @width, @height )
    assert w == @width
    assert h == @height
    assert byte_size(p) == @width * @height * 3
  end

  test "build :rgba works" do
    {@mutable, {w,h,:rgba}, p} = Texture.build( :rgba, @width, @height )
    assert w == @width
    assert h == @height
    assert byte_size(p) == @width * @height * 4
  end

  test "build honors the commit option" do
    {@texture, _, _} = Texture.build( :rgb, @width, @height, commit: true )
  end

  test "build honors the clear option" do
    color = Color.to_rgb({1, 2, 3})
    t = Texture.build( :rgb, @width, @height, clear: color )
    assert Texture.get(t, 2, 3) == color
  end


  #--------------------------------------------------------
  test "from_file works" do
    data = <<0,1,2,3,4,5,6>>
    {@texture, {w,h,:file}, d} = Texture.from_file( @width, @height, data )
    assert w == @width
    assert h == @height
    assert d == data
  end

  #--------------------------------------------------------
  test "commit changes a mutable texture to a committed one" do
    mut = Texture.build( :g, @width, @height )
    {@mutable, m_meta, m_pixels} = mut

    {@texture, c_meta, c_pixels} = Texture.commit(mut)
    assert c_meta == m_meta
    assert c_pixels == m_pixels
  end


  #--------------------------------------------------------
  test "mutable copies the pixels into a new mutable bin" do
    tex = Texture.build( :g, @width, @height, commit: true )
    {@texture, c_meta, c_pixels} = tex

    mut = Texture.mutable(tex)
    {@mutable, m_meta, m_pixels} = mut
    assert c_meta == m_meta
    assert c_pixels == m_pixels

    # we can confirm the pixels were copied by mutating the mutable one
    # and checking that the change is not also present in the tex version
    assert Texture.get( mut, 2, 2 ) == {:color_g, 0}
    
    assert Texture.get( tex, 2, 2 ) == {:color_g, 0}

    mut = Texture.put( mut, 2, 2, 5 )
    
    assert Texture.get( mut, 2, 2 ) == {:color_g, 5}
    assert Texture.get( tex, 2, 2 ) == {:color_g, 0}
  end


  #--------------------------------------------------------
  test "get :g works" do
    color = Color.to_g(5)

    tex = Texture.build( :g, @width, @height, clear: color, commit: true )
    assert Texture.get( tex, 2, 2 ) == color
    assert Texture.get( tex, 2, 3 ) == color
    assert Texture.get( tex, 2, 4 ) == color

    mut = Texture.build( :g, @width, @height, clear: color, commit: false )
    assert Texture.get( mut, 2, 2 ) == color
    assert Texture.get( mut, 2, 3 ) == color
    assert Texture.get( mut, 2, 4 ) == color
  end

  test "get :ga works" do
    color = Color.to_ga({5, 100})

    tex = Texture.build( :ga, @width, @height, clear: color, commit: true )
    assert Texture.get( tex, 2, 2 ) == color
    assert Texture.get( tex, 2, 3 ) == color
    assert Texture.get( tex, 2, 4 ) == color

    mut = Texture.build( :ga, @width, @height, clear: color, commit: false )
    assert Texture.get( mut, 2, 2 ) == color
    assert Texture.get( mut, 2, 3 ) == color
    assert Texture.get( mut, 2, 4 ) == color
  end

  test "get :rgb works" do
    color = Color.to_rgb({1, 2, 3})
    
    tex = Texture.build( :rgb, @width, @height, clear: color, commit: true )
    assert Texture.get( tex, 2, 2 ) == color
    assert Texture.get( tex, 2, 3 ) == color
    assert Texture.get( tex, 2, 4 ) == color
    
    mut = Texture.build( :rgb, @width, @height, clear: color, commit: false )
    assert Texture.get( mut, 2, 2 ) == color
    assert Texture.get( mut, 2, 3 ) == color
    assert Texture.get( mut, 2, 4 ) == color
  end

  test "get :rgba works" do
    color = Color.to_rgba({1, 2, 3, 100})
    
    tex = Texture.build( :rgba, @width, @height, clear: color, commit: true )
    assert Texture.get( tex, 2, 2 ) == color
    assert Texture.get( tex, 2, 3 ) == color
    assert Texture.get( tex, 2, 4 ) == color
    
    mut = Texture.build( :rgba, @width, @height, clear: color, commit: false )
    assert Texture.get( mut, 2, 2 ) == color
    assert Texture.get( mut, 2, 3 ) == color
    assert Texture.get( mut, 2, 4 ) == color
  end


  #--------------------------------------------------------
  test "put :g works" do
    color = Color.to_g(5)

    mut = Texture.build( :g, @width, @height )
    assert Texture.get( mut, 2, 2 ) == {:color_g, 0}
    mut = Texture.put( mut, 2, 2, color )
    assert Texture.get( mut, 2, 2 ) == color
  end

  test "put :ga works" do
    color = Color.to_ga({5, 100})

    mut = Texture.build( :ga, @width, @height )
    assert Texture.get( mut, 2, 2 ) == {:color_ga, {0, 0}}
    mut = Texture.put( mut, 2, 2, color )
    assert Texture.get( mut, 2, 2 ) == color
  end

  test "put :rgb works" do
    color = Color.to_rgb({1, 2, 3})
        
    mut = Texture.build( :rgb, @width, @height )
    assert Texture.get( mut, 2, 2 ) == {:color_rgb, {0, 0, 0}}
    mut = Texture.put( mut, 2, 2, color )
    assert Texture.get( mut, 2, 2 ) == color
  end

  test "put :rgba works" do
    color = Color.to_rgba({1, 2, 3, 100})
    
    mut = Texture.build( :rgba, @width, @height )
    assert Texture.get( mut, 2, 2 ) == {:color_rgba, {0, 0, 0, 0}}
    mut = Texture.put( mut, 2, 2, color )
    assert Texture.get( mut, 2, 2 ) == color
  end

  test "put raises if a committed texture is passed in" do
    color = Color.to_rgba({1, 2, 3, 100})

    tex = Texture.build( :rgba, @width, @height, commit: true )
    assert_raise FunctionClauseError, fn ->
      Texture.put( tex, 2, 2, color )
    end
  end

  #--------------------------------------------------------
  test "clear :g works" do
        color = Color.to_g(5)


    mut = Texture.build( :g, @width, @height )
    assert Texture.get( mut, 2, 2 ) == {:color_g, 0}

    mut = Texture.clear( mut, color )
    assert Texture.get( mut, 2, 2 ) == color
    assert Texture.get( mut, 2, 3 ) == color
    assert Texture.get( mut, 2, 4 ) == color
  end

  test "clear :ga works" do
    color = Color.to_ga({5, 100})

    mut = Texture.build( :ga, @width, @height )
    assert Texture.get( mut, 2, 2 ) == {:color_ga, {0, 0}}

    mut = Texture.put( mut, 2, 2, color )
    assert Texture.get( mut, 2, 2 ) == color
  end

  test "clear :rgb works" do
    color = Color.to_rgb({1, 2, 3})
        
    mut = Texture.build( :rgb, @width, @height )
    assert Texture.get( mut, 2, 2 ) == {:color_rgb, {0, 0, 0}}

    mut = Texture.clear( mut, color )
    assert Texture.get( mut, 2, 2 ) == color
    assert Texture.get( mut, 2, 3 ) == color
    assert Texture.get( mut, 2, 4 ) == color
  end

  test "clear :rgba works" do
    color = Color.to_rgba({1, 2, 3, 100})
    
    mut = Texture.build( :rgba, @width, @height )
    assert Texture.get( mut, 2, 2 ) == {:color_rgba, {0, 0, 0, 0}}

    mut = Texture.clear( mut, color )
    assert Texture.get( mut, 2, 2 ) == color
    assert Texture.get( mut, 2, 3 ) == color
    assert Texture.get( mut, 2, 4 ) == color
  end

  test "clear raises if a committed texture is passed in" do
    tex = Texture.build( :rgba, @width, @height, commit: true )
    assert_raise FunctionClauseError, fn ->
      Texture.clear( tex, {1, 2, 3, 100} )
    end
  end

end