#
#  Created by Boyd Multerer on 10/30/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Polygon do
  use Scenic.Primitive

# alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :color]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Polygon data must be list of points with at least three entries." <>
    "Like this: [{0,0}, {10,10}, {7,7}]"
  end

  #--------------------------------------------------------
  def verify( point_list ) when is_list(point_list) do
    if Enum.count(point_list) < 3 do
      false
    else
      do_verify_members(point_list)
    end
  end
  def verify( _ ), do: false
  defp do_verify_members([]), do: true
  defp do_verify_members([{x,y} | tail]) when is_number(x) and
  is_number(y), do: do_verify_members(tail)
  defp do_verify_members(_), do: false

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( point_list, :native ) do
#    { :ok,
#      <<
#        x         :: integer-size(16)-native,
#        y         :: integer-size(16)-native,
#        radius    :: integer-size(16)-native,
#        x_factor  :: integer-size(16)-native,
#        y_factor  :: integer-size(16)-native,
#      >>
#    }
    :err
  end
  def serialize( {{x, y}, radius, x_factor, y_factor}, :big ) do
#    { :ok,
#      <<
#        x         :: integer-size(16)-big,
#        y         :: integer-size(16)-big,
#        radius    :: integer-size(16)-big,
#        x_factor  :: integer-size(16)-big,
#        y_factor  :: integer-size(16)-big,
#      >>
#    }
    :err
  end

  #--------------------------------------------------------
  def deserialize( binary_data, order \\ :native )
  def deserialize( <<
      x         :: integer-size(16)-native,
      y         :: integer-size(16)-native,
      radius    :: integer-size(16)-native,
      x_factor  :: integer-size(16)-native,
      y_factor  :: integer-size(16)-native,
      bin       :: binary
    >>, :native ) do
    {:ok, {{x, y}, radius, x_factor, y_factor}, bin}
  end
  def deserialize( <<
      x         :: integer-size(16)-big,
      y         :: integer-size(16)-big,
      radius    :: integer-size(16)-big,
      x_factor  :: integer-size(16)-big,
      y_factor  :: integer-size(16)-big,
      bin       :: binary
    >>, :big ) do
    {:ok, {{x, y}, radius, x_factor, y_factor}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


  #============================================================================
  def valid_styles(), do: @styles


  #--------------------------------------------------------
  # naive, but good enough. average all the x's and y's
  def default_pin( points )
  def default_pin( [head | tail] ) do
    count = Enum.count(tail) + 1
    {x, y} = do_add_points(tail, head)
    {round(x / count), round(y / count)}
  end
  defp do_add_points([], acc), do: acc
  defp do_add_points([{x,y} | tail], {acc_x, acc_y}) do
    do_add_points(tail, {acc_x + x, acc_y + y})
  end

end