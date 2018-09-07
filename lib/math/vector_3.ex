#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.Vector3 do
  alias Scenic.Math.Vector3
  alias Scenic.Math.Matrix

  # a vector3 is a tuple with three dimentions. {x, y, z}

  # common constants
  def zero(), do: {0.0, 0.0, 0.0}
  def one(), do: {1.0, 1.0, 1.0}

  def unity_x(), do: {1.0, 0.0, 0.0}
  def unity_y(), do: {0.0, 1.0, 0.0}
  def unity_z(), do: {0.0, 0.0, 1.0}

  def up(), do: {0.0, 1.0, 0.0}
  def down(), do: {0.0, -1.0, 0.0}
  def left(), do: {-1.0, 0.0, 0.0}
  def right(), do: {1.0, 0.0, 0.0}
  def forward(), do: {0.0, 0.0, -1.0}
  def backward(), do: {0.0, 0.0, 1.0}

  # --------------------------------------------------------
  # build from values
  def build(x, y, z) when is_float(x) and is_float(y) and is_float(z), do: {x, y, z}

  # --------------------------------------------------------
  # add and subtract
  def add(a, b)
  def add({ax, ay, az}, {bx, by, bz}), do: {ax + bx, ay + by, az + bz}

  def sub(a, b)
  def sub({ax, ay, az}, {bx, by, bz}), do: {ax - bx, ay - by, az - bz}

  # --------------------------------------------------------
  # multiply by scalar
  def mul(a, s)
  def mul({ax, ay, az}, s) when is_float(s), do: {ax * s, ay * s, az * s}

  # --------------------------------------------------------
  # length
  def length_squared(a)
  def length_squared({ax, ay, az}), do: ax * ax + ay * ay + az * az

  def length(a)
  def length({ax, ay, az}), do: :math.sqrt(ax * ax + ay * ay + az * az)

  # --------------------------------------------------------
  # distance
  def distance_squared(a, b)

  def distance_squared({ax, ay, az}, {bx, by, bz}),
    do: (bx - ax) * (bx - ax) + (by - ay) * (by - ay) + (bz - az) * (bz - az)

  def distance(a, b)

  def distance({ax, ay, az}, {bx, by, bz}),
    do: :math.sqrt(distance_squared({ax, ay, az}, {bx, by, bz}))

  # --------------------------------------------------------
  # dot product
  def dot(a, b)
  def dot({ax, ay, az}, {bx, by, bz}), do: ax * bx + ay * by + az * bz

  # --------------------------------------------------------
  # cross product
  def cross(a, b)

  def cross({ax, ay, az}, {bx, by, bz}),
    do: {ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx}

  # --------------------------------------------------------
  # normalize
  def normalize(a)

  def normalize({ax, ay, az}) do
    case Vector3.length({ax, ay, az}) do
      0.0 ->
        {ax, ay, az}

      len ->
        {ax / len, ay / len, az / len}
    end
  end

  # --------------------------------------------------------
  # min / max

  def min(a, b)

  def min({ax, ay, az}, {bx, by, bz}) do
    x =
      cond do
        ax > bx -> bx
        true -> ax
      end

    y =
      cond do
        ay > by -> by
        true -> ay
      end

    z =
      cond do
        az > bz -> bz
        true -> az
      end

    {x, y, z}
  end

  def max(a, b)

  def max({ax, ay, az}, {bx, by, bz}) do
    x =
      cond do
        ax > bx -> ax
        true -> bx
      end

    y =
      cond do
        ay > by -> ay
        true -> by
      end

    z =
      cond do
        az > bz -> az
        true -> bz
      end

    {x, y, z}
  end

  # --------------------------------------------------------
  # clamp a vector between two other vectors
  def clamp(vector, min, max)

  def clamp({vx, vy, vz}, {minx, miny, minz}, {maxx, maxy, maxz}) do
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

    z =
      cond do
        vz < minz -> minz
        vz > maxz -> maxz
        true -> vz
      end

    {x, y, z}
  end

  # --------------------------------------------------------
  def in_bounds(vector, bounds)

  def in_bounds({vx, vy, vz}, {boundsx, boundsy, boundsz}),
    do:
      {vx, vy, vz} ==
        clamp({vx, vy, vz}, {-boundsx, -boundsy, -boundsz}, {boundsx, boundsy, boundsz})

  # --------------------------------------------------------
  def in_bounds(vector, min_bounds, max_bounds)

  def in_bounds({vx, vy, vz}, {minx, miny, minz}, {maxx, maxy, maxz}),
    do: {vx, vy, vz} == clamp({vx, vy, vz}, {minx, miny, minz}, {maxx, maxy, maxz})

  # --------------------------------------------------------
  # lerp( a, b, t )
  # https://keithmaggio.wordpress.com/2011/02/15/math-magician-lerp-slerp-and-nlerp/
  def lerp(a, b, t) when is_float(t) and t >= 0.0 and t <= 1.0 do
    sub(b, a)
    |> mul(t)
    |> add(a)
  end

  # --------------------------------------------------------
  # nlerp( a, b, t )
  # https://keithmaggio.wordpress.com/2011/02/15/math-magician-lerp-slerp-and-nlerp/
  def nlerp(a, b, t) when is_float(t) and t >= 0.0 and t <= 1.0 do
    sub(b, a)
    |> mul(t)
    |> add(a)
    |> normalize()
  end

  # --------------------------------------------------------
  # lerp( a, b, t )
  # https://keithmaggio.wordpress.com/2011/02/15/math-magician-lerp-slerp-and-nlerp/
  def slerp(a, b, t) when is_float(t) and t >= 0.0 and t <= 1.0 do
    dot = dot(a, b)

    dot =
      cond do
        dot < -1.0 -> -1.0
        dot > 1.0 -> 1.0
      end

    # acos(dot) returns the angle between start and end
    # multiplying that by t returns the angle between start and final
    theta = :math.acos(dot) * t

    relative_vec =
      sub(b, mul(a, dot))
      |> normalize()

    # finish it up
    mul(a, :math.cos(theta))
    |> add(mul(relative_vec, :math.sin(theta)))
  end

  # --------------------------------------------------------
  def project({x, y, z}, matrix) do
    Matrix.project_vector(matrix, {x, y, z})
  end

  # --------------------------------------------------------
  def project(vectors, matrix) do
    Matrix.project_vector3s(matrix, vectors)
  end
end
