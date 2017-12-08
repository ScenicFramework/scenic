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

    # strip the input-only opts out
    stripped_opts = opts
    |> Keyword.delete(:name)
    |> Keyword.delete(:value)

    # build the basic graph
    Graph.build(stripped_opts)
    # set the optional input name
    |> build_name_opt( opts[:name] )
    # set the optional input value
    |> build_value_opt( opts[:value] )
  end

  defp build_name_opt( input_graph, name )
  defp build_name_opt( input_graph, nil ),  do: input_graph
  defp build_name_opt( input_graph, name )  when is_bitstring(name) do
    Graph.get(input_graph, 0)
    |> put_name( name )
    |> ( &Graph.put(input_graph, 0, &1) ).()
  end
  defp build_name_opt( _, _ ) do
    raise Error, "Input name option must be a bitstring"
  end

  defp build_value_opt( input_graph, value )
  defp build_value_opt( input_graph, nil ),  do: input_graph
  defp build_value_opt( input_graph, value ) do
    Graph.get(input_graph, 0)
    |> put_value( value )
    |> ( &Graph.put(input_graph, 0, &1) ).()
  end

  #===========================================================================
  # access to the internal values

  #--------------------------------------------------------
  def get_value( input, default \\ nil )
  def get_value( %Primitive{} = input, default ) do
    Map.get( input, :input_value, default )
  end

  def put_value( input, value )
  def put_value( %Primitive{} = input, value ) do
    case value do
      nil   -> Map.delete( input, :input_value )
      value -> Map.put(input, :input_value, value)
    end
  end

  #--------------------------------------------------------
  def get_name( input, default \\ nil )
  def get_name( %Primitive{} = input, default ) do
    Map.get( input, :input_name, default )
  end

  def put_name( input, name )
  def put_name( %Primitive{} = input, name ) do
    case name do
      nil   -> Map.delete( input, :input_name )
      name -> Map.put(input, :input_name, name)
    end
  end

end













