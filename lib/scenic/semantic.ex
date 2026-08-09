defmodule Scenic.Semantic do
  @moduledoc """
  Semantic information helpers for Scenic components.
  
  Provides consistent semantic annotations for testing and accessibility.
  """
  
  @doc """
  Mark an element as a button.
  
  ## Examples
      |> rect({100, 40}, semantic: Scenic.Semantic.button("Submit"))
  """
  def button(label) do
    %{type: :button, label: label, role: :button}
  end
  
  @doc """
  Mark an element as an editable text buffer.
  
  ## Examples
      |> text(content, semantic: Scenic.Semantic.text_buffer(buffer_id: 1))
  """
  def text_buffer(opts) do
    %{
      type: :text_buffer,
      buffer_id: Keyword.fetch!(opts, :buffer_id),
      editable: Keyword.get(opts, :editable, true),
      role: :textbox
    }
  end
  
  @doc """
  Mark an element as a text input field.
  """
  def text_input(name, opts \\ []) do
    %{
      type: :text_input,
      name: name,
      value: Keyword.get(opts, :value),
      placeholder: Keyword.get(opts, :placeholder),
      role: :textbox
    }
  end
  
  @doc """
  Mark an element as a menu.
  """
  def menu(name, opts \\ []) do
    %{
      type: :menu,
      name: name,
      orientation: Keyword.get(opts, :orientation, :vertical),
      role: :menu
    }
  end
  
  @doc """
  Mark an element as a menu item.
  """
  def menu_item(label, opts \\ []) do
    %{
      type: :menu_item,
      label: label,
      parent_menu: Keyword.get(opts, :parent_menu),
      role: :menuitem
    }
  end
  
  @doc """
  Generic semantic annotation.
  """
  def annotate(type, attrs \\ %{}) do
    Map.merge(%{type: type}, attrs)
  end
end