defmodule Scenic.Test.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Machete
      import Scenic.Test.SortedListMatcher
      import Scenic.Test.Assertions
    end
  end
end
