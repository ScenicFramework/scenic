#
#  Created by Boyd Multerer on 10/26/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#
# Line utility functions

defmodule Scenic.Math.Line do
  alias Scenic.Math

  # import IEx

  @app Mix.Project.config[:app]
  # @env Mix.env

  # load the NIF
  @on_load :load_nifs
  def load_nifs do
    app = :code.priv_dir(@app)
    # env = to_charlist(@env)
    # path = :filename.join(:code.priv_dir(@app), to_charlist(@env) ++ '/line')
    path = app ++ '/line'
    :ok = :filename.join(:code.priv_dir(@app), path)
    |> :erlang.load_nif(0)
  end


  #--------------------------------------------------------
  # truncate the values into ints
  def trunc( {p0, p1} ) do
    {
      Math.Vector.trunc(p0),
      Math.Vector.trunc(p1)
    }
  end

  #--------------------------------------------------------
  # round the values into ints
  def round( {p0, p1} ) do
    {
      Math.Vector.round(p0),
      Math.Vector.round(p1)
    }
  end

  #--------------------------------------------------------
  # make a parallel line a distance from the given line
  def parallel({{x0, y0}, {x1, y1}} , w ) do
    nif_parallel(x0, y0, x1, y1, w)
  end
  defp nif_parallel(_,_,_,_,_),             do: raise "Did not find nif_parallel"

  #--------------------------------------------------------
  # find the point of intersection between two lines
  def intersection({{x0, y0}, {x1, y1}}, {{x2, y2}, {x3, y3}}) do
    nif_intersection(x0, y0, x1, y1, x2, y2, x3, y3)
  end
  defp nif_intersection(_,_,_,_,_,_,_,_),   do: raise "Did not find nif_intersection"

end
