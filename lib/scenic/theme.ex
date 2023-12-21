defmodule Scenic.Theme do
  @moduledoc """
  A Theme is a collection of settings for things like font, color pallettes, and so forth.
  """
  defstruct font: nil, pallette: %{}, name: nil

  @type pallette :: %{
          atom() => Scenic.Color.t()
        }

  @typedoc """
  A Theme is a collection of settings for things like font, color pallettes, and so forth.

  The available themeable properties are:

  * `name` is the atom identifying a theme.
  * `font` is a String of the font that a theme should use, or nil if no preference.
  * `pallette` is a map mapping atoms like `:primary` or `:secondary` to a `Scenic.Color`.
  """
  @type t :: %__MODULE__{
          name: :atom,
          font: String.t() | nil,
          pallette: pallette()
        }

  @doc """
  Creates a theme object with a given name.
  """
  @spec create(any) :: {:ok, t()} | {:error, String.t()}
  def create(name) when is_atom(name), do: {:ok, %__MODULE__{name: name}}
  def create(_), do: {:error, "Themes must be named with an atom."}

  @doc """
  Creates a theme object with the given name. If not given an atom for the name, throws.
  """
  @spec create!(any()) :: t() | no_return()
  def create!(name) do
    case create(name) do
      {:ok, theme} -> theme
      {:error, msg} -> raise msg
    end
  end

  @doc """
  Upserts a given setting on a provided theme object.

  Current supported settings are:

  * `font` , which takes a `String.t`.
  * `pallette` , which takes a `pallette()`.
  """
  @spec put_setting(t(), atom, String.t() | pallette()) :: t()
  def put_setting(%__MODULE__{} = theme, :font, font_name), do: %{theme | font: font_name}

  def put_setting(%__MODULE__{} = theme, :pallette, pallette) when is_map(pallette),
    do: %{theme | pallette: pallette}
end
