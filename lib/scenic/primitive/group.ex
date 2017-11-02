#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Group do
  use Scenic.Primitive
  alias Scenic.Primitive
#  alias Scenic.Graph

#  import IEx

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def build(nil, opts), do: build([], opts)
  def build(ids, opts) do
    verify!( ids )
    Primitive.build(__MODULE__, ids, opts)
  end


  #--------------------------------------------------------
  def info(), do: "Group data is managed internally."

  #--------------------------------------------------------
  def verify( ids ) when is_list(ids) do
    Enum.all?(ids, fn(id)-> is_integer(id) end)
  end
  def verify( _ ), do: false

  #--------------------------------------------------------
  def serialize( ids, order \\ :native )
  def serialize( ids, :native ) when is_list(ids) do
    # count and serialize the list in one pass
    {bin, count} = Enum.reduce(ids, {<<>>,0}, fn(id, {bin,c})->
      {
        <<
          bin :: binary,
          id  :: unsigned-integer-native-size(32)
        >>,
        c + 1
      }
    end)

    # prepend the count and return
    {
      :ok, 
      <<
        count :: unsigned-integer-native-size(16),
        bin   :: binary
      >>
    }
  end
  def serialize( ids, :big ) when is_list(ids) do
    # count and serialize the list in one pass
    {bin, count} = Enum.reduce(ids, {<<>>,0}, fn(id, {bin,c})->
      {
        <<
          bin :: binary,
          id  :: unsigned-integer-big-size(32)
        >>,
        c + 1
      }
    end)

    # prepend the count and return
    {
      :ok, 
      <<
        count :: unsigned-integer-big-size(16),
        bin   :: binary
      >>
    }
  end

  #--------------------------------------------------------
  def deserialize( binary_data, order \\ :native )
  def deserialize( <<
      num_ids   :: unsigned-integer-native-size( 16 ),
      bin       :: binary
    >>, :native ) do
    do_deserialize( :native, num_ids, bin )
  end
  def deserialize( <<
      num_ids   :: unsigned-integer-big-size( 16 ),
      bin       :: binary
    >>, :big ) do
    do_deserialize( :big, num_ids, bin )
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }

  defp do_deserialize( order, num_ids, bin, ids \\ [] )
  defp do_deserialize( _, 0, bin, ids ), do: {:ok, Enum.reverse(ids), bin}
  defp do_deserialize( :native, num_ids, << id :: unsigned-integer-native-size(32), bin :: binary >>, ids ) do
    do_deserialize( :native, num_ids - 1, bin, [ id | ids] )
  end
  defp do_deserialize( :big, num_ids, << id :: unsigned-integer-big-size(32), bin :: binary >>, ids ) do
    do_deserialize( :big, num_ids - 1, bin, [ id | ids] )
  end



  #============================================================================
  # filter and gather styles

  def valid_styles(),                               do: [:all]
  def filter_styles( styles ) when is_map(styles),  do: styles

  # gather the primitive styles on the build opts and take them
#  def build( data, opts ) do
#    styles = Enum.into(opts, %{})
#    |> Primitive.Styles.primitive()
#    super(data, [styles: styles])
#  end


  #============================================================================
  # apis to manipulate the list of child ids

  #----------------------------------------------------------------------------
  def insert_at( %Primitive{module: __MODULE__, data: uid_list} = p, index, uid ) do
    Map.put(
      p,
      :data,
      List.insert_at(uid_list, index, uid)
    )
  end

  #----------------------------------------------------------------------------
  def delete( %Primitive{module: __MODULE__, data: uid_list} = p, uid ) do
    Map.put(
      p,
      :data,
      Enum.reject(uid_list, fn(xid)-> xid == uid end)
    )
  end

  #----------------------------------------------------------------------------
  def increment( %Primitive{module: __MODULE__, data: uid_list} = p, offset ) do
    Map.put(
      p,
      :data,
      Enum.map(uid_list, fn(xid)-> xid + offset end)
    )
  end

  #--------------------------------------------------------
  def default_pin( data )
  def default_pin( _ ) do
    {0,0}
  end

end