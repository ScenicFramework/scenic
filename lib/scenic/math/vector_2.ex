#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.Vector2 do
  @moduledoc """
  A collection of functions to work with 2D vectors.

  2D vectors are always two numbers in a tuple.

      {3, 4}
      {3.5, 4.7}
  """

  alias Scenic.Math
  alias Scenic.Math.Vector2
  alias Scenic.Math.Matrix

  # common constants
  @doc "A vector that points to the origin."
  def zero(), do: {0.0, 0.0}

  @doc "A vector that points to {1,1}."
  def one(), do: {1.0, 1.0}

  @doc "A vector that points to {1,0}."
  def unity_x(), do: {1.0, 0.0}

  @doc "A vector that points to {0,1}."
  def unity_y(), do: {0.0, 1.0}

  @doc "A vector that points straight up by 1."
  def up(), do: {0.0, 1.0}

  @doc "A vector that points straight down by 1."
  def down(), do: {0.0, -1.0}

  @doc "A vector that points left by 1."
  def left(), do: {-1.0, 0.0}

  @doc "A vector that points right by 1."
  def right(), do: {1.0, 0.0}

  # --------------------------------------------------------
  @doc """
  Truncate the values of a vector into integers.

  Parameters:
  * `vector_2` - the vector to be truncated

  Returns:
  The integer vector

  ## Examples

      iex> Scenic.Math.Vector2.trunc({1.6, 1.2})
      {1, 1}

  """
  @spec trunc(vector_2 :: Math.vector_2()) :: Math.vector_2()
  def trunc(vector_2)

  def trunc({x, y}) do
    {Kernel.trunc(x), Kernel.trunc(y)}
  end

  # --------------------------------------------------------
  @doc """
  Round the values of a vector to the nearest integers.

  Parameters:
  * `vector_2` - the vector to be rounded

  Returns:
  The integer vector

  ## Examples

      iex> Scenic.Math.Vector2.round({1.2, 1.56})
      {1, 2}

  """
  @spec round(vector_2 :: Math.vector_2()) :: Math.vector_2()
  def round(vector_2)

  def round({x, y}) do
    {Kernel.round(x), Kernel.round(y)}
  end

  # --------------------------------------------------------
  @doc """
  Invert a vector.

  Parameters:
  * `vector_2` - the vector to be inverted

  Returns:
  The inverted vector

  ## Examples

      iex> Scenic.Math.Vector2.invert({2, 2})
      {-2, -2}

  """
  @spec invert(vector_2 :: Math.vector_2()) :: Math.vector_2()
  def invert(vector_2)
  def invert({x, y}), do: {-x, -y}

  # --------------------------------------------------------
  # add and subtract
  @doc """
  Add two vectors together.

  Parameters:
  * `vector2_a` - the first vector to be added
  * `vector2_b` - the second vector to be added

  Returns:
  A new vector which is the result of the addition

  ## Examples

      iex> Scenic.Math.Vector2.add({1.0, 5.0}, {3.0, 3.0})
      {4.0, 8.0}

  """
  @spec add(vector2_a :: Math.vector_2(), vector2_b :: Math.vector_2()) :: Math.vector_2()
  def add(vector2_a, vector2_b)
  def add({ax, ay}, {bx, by}), do: {ax + bx, ay + by}

  @doc """
  Subtract one vector from another.

  Parameters:
  * `vector2_a` - the first vector
  * `vector2_b` - the second vector, which will be subtracted from the first

  Returns:
  A new vector which is the result of the subtraction
  """
  @spec sub(vector2_a :: Math.vector_2(), vector2_b :: Math.vector_2()) :: Math.vector_2()
  def sub(vector2_a, vector2_b)
  def sub({ax, ay}, {bx, by}), do: {ax - bx, ay - by}

  # --------------------------------------------------------
  @doc """
  Multiply a vector by a scalar.

  Parameters:
  * `vector2` - the vector
  * `scalar` - the scalar value

  Returns:
  A new vector which is the result of the multiplication
  """
  @spec mul(vector2 :: Math.vector_2(), scalar :: number) :: Math.vector_2()
  def mul(vector2_a, vector2_b)
  def mul({ax, ay}, s) when is_number(s), do: {ax * s, ay * s}

  # --------------------------------------------------------
  @doc """
  Divide a vector by a scalar.

  Parameters:
  * `vector2` - the vector
  * `scalar` - the scalar value

  Returns:
  A new vector which is the result of the division
  """
  @spec div(vector2 :: Math.vector_2(), scalar :: number) :: Math.vector_2()
  def div(vector2_a, vector2_b)
  def div({ax, ay}, s) when is_number(s), do: {ax / s, ay / s}

  # --------------------------------------------------------
  @doc """
  Calculates the dot product of two vectors.

  Parameters:
  * `vector2_a` - the first vector
  * `vector2_b` - the second vector

  Returns:
  A number which is the result of the dot product
  """
  @spec dot(vector2_a :: Math.vector_2(), vector2_b :: Math.vector_2()) :: number
  def dot(vector2_a, vector2_b)
  def dot({ax, ay}, {bx, by}), do: ax * bx + ay * by

  # --------------------------------------------------------
  # cross product https://www.gamedev.net/topic/289972-cross-product-of-2d-vectors/
  @doc """
  Calculates the cross product of two vectors.

  Parameters:
  * `vector2_a` - the first vector
  * `vector2_b` - the second vector

  Returns:
  A number which is the result of the cross product
  """
  @spec cross(vector2_a :: Math.vector_2(), vector2_b :: Math.vector_2()) :: number
  def cross(vector2_a, vector2_b)
  def cross({ax, ay}, {bx, by}), do: ax * by - ay * bx

  # --------------------------------------------------------
  # length
  @doc """
  Calculates the squared length of the vector.

  This is faster than calculating the length if all you want to do is
  compare the lengths of two vectors against each other.

  Parameters:
  * `vector2` - the vector

  Returns:
  A number which is the square of the length
  """
  @spec length_squared(vector2 :: Math.vector_2()) :: number
  def length_squared(vector2)
  def length_squared({ax, ay}), do: ax * ax + ay * ay

  @doc """
  Calculates the length of the vector.

  This is slower than calculating the squared length.

  Parameters:
  * `vector2` - the vector

  Returns:
  A number which is the length
  """
  @spec length(vector2 :: Math.vector_2()) :: number
  def length(vector2)
  def length(vector2), do: vector2 |> length_squared() |> :math.sqrt()

  # --------------------------------------------------------
  # distance
  def distance_squared(a, b)

  def distance_squared({ax, ay}, {bx, by}),
    do: (bx - ax) * (bx - ax) + (by - ay) * (by - ay)

  def distance(vector2_a, vector2_b)
  def distance({ax, ay}, {bx, by}), do: :math.sqrt(distance_squared({ax, ay}, {bx, by}))

  # --------------------------------------------------------
  # normalize

  @doc """
  Normalize a vector so it has the same angle, but a length of 1.

  Parameters:
  * `vector2` - the vector

  Returns:
  A vector with the same angle as the original, but a length of 1
  """
  @spec normalize(vector2 :: Math.vector_2()) :: Math.vector_2()
  def normalize(vector2)

  def normalize({ax, ay}) do
    case Vector2.length({ax, ay}) do
      0.0 ->
        {ax, ay}

      len ->
        {ax / len, ay / len}
    end
  end

  # --------------------------------------------------------
  # min / max
  @doc """
  Find a new vector derived from the lowest `x` and `y` from two given vectors.

  Parameters:
  * `vector2_a` - the first vector
  * `vector2_b` - the second vector

  Returns:
  A vector derived from the lowest `x` and `y` from two given vectors
  """
  @spec min(vector2_a :: Math.vector_2(), vector2_b :: Math.vector_2()) :: Math.vector_2()
  def min(vector2_a, vector2_b)

  def min({ax, ay}, {bx, by}) do
    x = if ax > bx, do: bx, else: ax

    y = if ay > by, do: by, else: ay

    {x, y}
  end

  @doc """
  Find a new vector derived from the highest `x` and `y` from two given vectors.

  Parameters:
  * `vector2_a` - the first vector
  * `vector2_b` - the second vector

  Returns:
  A vector derived from the highest `x` and `y` from two given vectors
  """
  @spec max(vector2_a :: Math.vector_2(), vector2_b :: Math.vector_2()) :: Math.vector_2()
  def max(vector2_a, vector2_b)

  def max({ax, ay}, {bx, by}) do
    x = if ax > bx, do: ax, else: bx

    y = if ay > by, do: ay, else: by

    {x, y}
  end

  # --------------------------------------------------------
  @doc """
  Clamp a vector to the space between two other vectors.

  Parameters:
  * `vector2` - the vector to be clamped
  * `min` - the vector defining the minimum boundary
  * `max` - the vector defining the maximum boundary

  Returns:
  A vector derived from the space between two other vectors
  """
  @spec clamp(vector :: Math.vector_2(), min :: Math.vector_2(), max :: Math.vector_2()) ::
          Math.vector_2()
  def clamp(vector, min, max)

  def clamp({vx, vy}, {minx, miny}, {maxx, maxy}) do
    x =
      cond do
        vx < minx -> minx
        vx > maxx -> maxx
        true -> vx
      end

    y =
      cond do
        vy < miny -> miny
        vy > maxy -> maxy
        true -> vy
      end

    {x, y}
  end

  # --------------------------------------------------------
  @doc """
  Determine if a vector is in the bounds (or clamp space) between
  two other vectors.

  Parameters:
  * `vector2` - the vector to be tested
  * `bounds` - a vector defining the boundary

  Returns:
  true or false
  """
  @spec in_bounds?(vector :: Math.vector_2(), bounds :: Math.vector_2()) :: boolean
  def in_bounds?(vector, bounds)

  def in_bounds?({vx, vy}, {boundsx, boundsy}),
    do: {vx, vy} == clamp({vx, vy}, {-boundsx, -boundsy}, {boundsx, boundsy})

  # --------------------------------------------------------
  @doc """
  Determine if a vector is in the bounds (or clamp space) between
  two other vectors.

  Parameters:
  * `vector2` - the vector to be tested
  * `min` - the vector defining the minimum boundary
  * `max` - the vector defining the maximum boundary

  Returns:
  A vector derived from the space between two other vectors
  """
  @spec in_bounds?(vector :: Math.vector_2(), min :: Math.vector_2(), max :: Math.vector_2()) ::
          boolean
  def in_bounds?(vector, min, max)

  def in_bounds?({vx, vy}, {minx, miny}, {maxx, maxy}),
    do: {vx, vy} == clamp({vx, vy}, {minx, miny}, {maxx, maxy})

  # --------------------------------------------------------
  @doc """
  Calculate the lerp of two vectors.

  [See This explanation for more info.](https://keithmaggio.wordpress.com/2011/02/15/math-magician-lerp-slerp-and-nlerp/)

  Parameters:
  * `vector_a` - the first vector
  * `vector_b` - the second vector
  * `t` - the "t" value (see link above). Must be between 0 and 1.

  Returns:
  A vector, which is the result of the lerp.
  """
  @spec lerp(
          vector_a :: Math.vector_2(),
          vector_b :: Math.vector_2(),
          t :: number
        ) :: Math.vector_2()
  def lerp(vector_a, vector_a, t)

  def lerp(a, b, t) when is_float(t) and t >= 0.0 and t <= 1.0 do
    b
    |> sub(a)
    |> mul(t)
    |> add(a)
  end

  # --------------------------------------------------------
  @doc """
  Calculate the nlerp (normalized lerp) of two vectors.

  [See This explanation for more info.](https://keithmaggio.wordpress.com/2011/02/15/math-magician-lerp-slerp-and-nlerp/)

  Parameters:
  * `vector_a` - the first vector
  * `vector_b` - the second vector
  * `t` - the "t" value (see link above). Must be between 0 and 1.

  Returns:
  A vector, which is the result of the nlerp.
  """
  @spec nlerp(
          vector_a :: Math.vector_2(),
          vector_b :: Math.vector_2(),
          t :: number
        ) :: Math.vector_2()
  def nlerp(vector_a, vector_a, t)

  def nlerp(a, b, t) when is_float(t) and t >= 0.0 and t <= 1.0 do
    b
    |> sub(a)
    |> mul(t)
    |> add(a)
    |> normalize()
  end

  # --------------------------------------------------------
  @doc """
  Project a vector into the space defined by a matrix

  Parameters:
  * `vector` - the vector, or a list of vectors
  * `matrix` - the matrix

  Returns:
  A projected vector (or list of vectors)
  """
  @spec project(
          vector :: Math.vector_2() | list(Math.vector_2()),
          matrix :: Math.matrix()
        ) :: Math.vector_2() | list(Math.vector_2())
  def project(vector_a, matrix)

  def project({x, y}, matrix) do
    Matrix.project_vector(matrix, {x, y})
  end

  def project(vectors, matrix) do
    Matrix.project_vectors(matrix, vectors)
  end
end
