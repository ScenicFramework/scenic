defmodule Scenic.Test.Assertions do
  import ExUnit.Assertions

  def assert_match_list(list1, list2) do
    assert Enum.sort(list1) == Enum.sort(list2)
  end
end

defmodule Scenic.Test.SortedListMatcher do
  @moduledoc """
  Defines a matcher that matches falsy values
  """

  import Machete.Mismatch

  defstruct [:values]

  @typedoc """
  Describes an instance of this matcher
  """
  @opaque t :: %__MODULE__{}

  @typedoc """
  Describes the arguments that can be passed to this matcher
  """
  @type opts :: []

  @doc """
  Matches against [falsy values](https://hexdocs.pm/elixir/1.12/Kernel.html#module-truthy-and-falsy-values)

  Takes no arguments

  Examples:

      iex> assert false ~> falsy()
      true

      iex> assert nil ~> falsy()
      true

      iex> refute true ~> falsy()
      false
  """
  @spec sorted_list(list()) :: t()
  def sorted_list(list \\ []) do
    struct!(__MODULE__, values: list)
  end

  defimpl Machete.Matchable do
    def mismatches(%@for{} = a, b) do
      list_a = Enum.sort(a.values)
      list_b = Enum.sort(b)

      if list_a == list_b do
        nil
      else
        mismatch("#{inspect(list_b)} does not match #{inspect(list_a)}")
      end
    end
  end
end
