defmodule Scenic.Template.Input do
  alias Scenic.Graph
  alias Scenic.Primitive

  # format of state for all standard input controls
  # {:input, name, value, state}

  #===========================================================================
  defmodule Error do
    defexception [ message: nil ]
  end


  #===========================================================================
  defmacro __using__(_opts) do
    quote do
      use Scenic.Template

      #--------------------------------------------------------
#      defoverridable [
#        put_style:  3
#      ]
    end # quote
  end # defmacro


  #===========================================================================
  def build( opts \\ [] )
  def build( opts) do
    # build the state
    state = {
      :input,
      prep_name_opt( opts[:name] ),
      opts[:value],
      opts[:state]      # input specific sub-state
    }

    # set the state in the options list
    opts = opts
      |> Keyword.put( :state, state )

    # build the basic graph, with the offset
    Graph.build(opts)
  end

  defp prep_name_opt( name )
  defp prep_name_opt( nil ),  do: nil
  defp prep_name_opt( name )  when is_bitstring(name), do: name
  defp prep_name_opt( _ ) do
    raise Error, "Input name option must be a bitstring"
  end

  #===========================================================================
  # access to the internal values

  #--------------------------------------------------------
  def get_value( input )
  def get_value( input ) do
    {:input, _, value, _} = Primitive.get_state( input )
    value
  end

  def put_value( input, value )
  def put_value( input, value ) do
    {:input, name, _, state} = Primitive.get_state( input )
    Primitive.put_state(input, {:input, name, value, state} )
  end

  #--------------------------------------------------------
  def get_name( input )
  def get_name( input ) do
    {:input, name, _, _} = Primitive.get_state( input )
    name
  end

  def put_name( input, name )
  def put_name( input, name ) when is_bitstring(name) do
    {:input, _, value, state} = Primitive.get_state( input )
    Primitive.put_state(input, {:input, name, value, state} )
  end

  #--------------------------------------------------------
  # access to the internal sub-state
  def get_state( input )
  def get_state( input ) do
    {:input, _, _, state} = Primitive.get_state( input )
    state
  end

  def put_state( input, state )
  def put_state( input, state ) do
    {:input, name, value, _} = Primitive.get_state( input )
    Primitive.put_state(input, {:input, name, value, state} )
  end

end













