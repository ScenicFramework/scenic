defmodule Scenic.Utilities.Validators do
  @moduledoc false

  def validate_xy({x, y}, _) when is_number(x) and is_number(y), do: {:ok, {x, y}}

  def validate_xy(data, name) do
    {
      :error,
      """
      #{IO.ANSI.red()}The #{inspect(name)} option must be { x, y }
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
      """
    }
  end

  def validate_wh({w, h}, _) when is_number(w) and is_number(h), do: {:ok, {w, h}}

  def validate_wh(data, name) do
    {
      :error,
      """
      #{IO.ANSI.red()}The #{inspect(name)} option must be { width, height }
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
      """
    }
  end

  def validate_scene(mod, _) when is_atom(mod), do: {:ok, {mod, nil}}
  def validate_scene({mod, param}, _) when is_atom(mod), do: {:ok, {mod, param}}

  def validate_scene(data, name) do
    {
      :error,
      """
      #{IO.ANSI.red()}The #{inspect(name)} option must be SceneModule or { SceneModule, param }
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
      """
    }
  end

  def validate_vp(%Scenic.ViewPort{} = vp, _), do: {:ok, vp}

  def validate_vp(data, name) do
    {
      :error,
      """
      #{IO.ANSI.red()}The #{inspect(name)} option must be %Scenic.ViewPort{} struct
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
      """
    }
  end
end
