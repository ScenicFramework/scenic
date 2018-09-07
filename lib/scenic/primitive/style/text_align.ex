#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextAlign do
  use Scenic.Primitive.Style
  #  alias Scenic.Primitive.Style

  #  @dflag            Style.dflag()
  #  @type_code        0x0020

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be one of ...
      :left, :right, :center, # (vertically on the baseline)
      :left_top, :right_top, :center_top,
      :left_middle, :right_middle, :center_middle,
      :left_bottom, :right_bottom, :center_bottom
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify(align) do
    try do
      normalize(align)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  def normalize(:left = align), do: align
  def normalize(:right = align), do: align
  def normalize(:center = align), do: align

  def normalize(:left_top = align), do: align
  def normalize(:right_top = align), do: align
  def normalize(:center_top = align), do: align

  def normalize(:left_middle = align), do: align
  def normalize(:right_middle = align), do: align
  def normalize(:center_middle = align), do: align

  def normalize(:left_bottom = align), do: align
  def normalize(:right_bottom = align), do: align
  def normalize(:center_bottom = align), do: align
end
