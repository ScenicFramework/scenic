#
#  Created by Boyd Multerer on 2017-11-12.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#
defmodule Scenic.Cache do
  @moduledoc """
  This module is deprecated, please use the specific caches instead.

  The Scenic.Cache module will be removed in a future release.

  | Asset Class   | Module  |
  | ------------- | -----|
  | Fonts      | [Scenic.Cache.Font](Scenic.Cache.Font.html) |
  | Font Metrics | [Scenic.Cache.FontMetrics](Scenic.Cache.FontMetrics.html) |
  | Textures (images in a fill) | [Scenic.Cache.Texture](Scenic.Cache.Texture.html) |
  """
 
  @doc """
  This function is deprecated, please use the specific cache modules instead.

  | Asset Class   | Module  |
  | ------------- | -----|
  | Fonts      | [Scenic.Cache.Font](Scenic.Cache.Font.html) |
  | Font Metrics | [Scenic.Cache.FontMetrics](Scenic.Cache.FontMetrics.html) |
  | Textures (images in a fill) | [Scenic.Cache.Texture](Scenic.Cache.Texture.html) |
  """
  @deprecated "Use get in the appropriate cache module"
  def get(key, default \\ nil)
  def get(_, _) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.get/2 has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please use the functions in the appropriate type-specific cache module.

    Asset Class                 | Module
    ----------------------------|--------------------------------
    Fonts                       | Scenic.Cache.Static.Font
    Font Metrics                | Scenic.Cache.Static.FontMetrics
    Textures (images in a fill) | Scenic.Cache.Static.Texture
    #{IO.ANSI.default_color()}
    """
  end

  @doc """
  This function is deprecated, please use the specific cache modules instead.

  | Asset Class   | Module  |
  | ------------- | -----|
  | Fonts      | [Scenic.Cache.Font](Scenic.Cache.Font.html) |
  | Font Metrics | [Scenic.Cache.FontMetrics](Scenic.Cache.FontMetrics.html) |
  | Textures (images in a fill) | [Scenic.Cache.Texture](Scenic.Cache.Texture.html) |
  """
  @deprecated "Use fetch in the appropriate cache module"
  def fetch(key)
  def fetch(_) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.fetch/1 has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please use the functions in the appropriate type-specific cache module.

    Asset Class                 | Module
    ----------------------------|--------------------------------
    Fonts                       | Scenic.Cache.Static.Font
    Font Metrics                | Scenic.Cache.Static.FontMetrics
    Textures (images in a fill) | Scenic.Cache.Static.Texture
    #{IO.ANSI.default_color()}
    """
  end

  @doc """
  This function is deprecated, please use the specific cache modules instead.

  | Asset Class   | Module  |
  | ------------- | -----|
  | Fonts      | [Scenic.Cache.Font](Scenic.Cache.Font.html) |
  | Font Metrics | [Scenic.Cache.FontMetrics](Scenic.Cache.FontMetrics.html) |
  | Textures (images in a fill) | [Scenic.Cache.Texture](Scenic.Cache.Texture.html) |
  """
  @deprecated "Use get! in the appropriate cache module"
  def get!(key)

  def get!(_) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.get!/1 has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please use the functions in the appropriate type-specific cache module.

    Asset Class                 | Module
    ----------------------------|--------------------------------
    Fonts                       | Scenic.Cache.Static.Font
    Font Metrics                | Scenic.Cache.Static.FontMetrics
    Textures (images in a fill) | Scenic.Cache.Static.Texture
    #{IO.ANSI.default_color()}
    """
  end

  @doc """
  This function is deprecated, please use the specific cache modules instead.

  | Asset Class   | Module  |
  | ------------- | -----|
  | Fonts      | [Scenic.Cache.Font](Scenic.Cache.Font.html) |
  | Font Metrics | [Scenic.Cache.FontMetrics](Scenic.Cache.FontMetrics.html) |
  | Textures (images in a fill) | [Scenic.Cache.Texture](Scenic.Cache.Texture.html) |
  """
  @deprecated "Use put in the appropriate cache module"
  def put(key, data, scope \\ nil)
  def put(_, _, _) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.put/3 has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please use the functions in the appropriate type-specific cache module.

    Asset Class                 | Module
    ----------------------------|--------------------------------
    Fonts                       | Scenic.Cache.Static.Font
    Font Metrics                | Scenic.Cache.Static.FontMetrics
    Textures (images in a fill) | Scenic.Cache.Static.Texture
    #{IO.ANSI.default_color()}
    """
  end

  @doc """
  This function is deprecated, please use the specific cache modules instead.

  | Asset Class   | Module  |
  | ------------- | -----|
  | Fonts      | [Scenic.Cache.Font](Scenic.Cache.Font.html) |
  | Font Metrics | [Scenic.Cache.FontMetrics](Scenic.Cache.FontMetrics.html) |
  | Textures (images in a fill) | [Scenic.Cache.Texture](Scenic.Cache.Texture.html) |
  """
  @deprecated "Use claim in the appropriate cache module"
  def claim(key, scope \\ nil)
  def claim(_, _) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.claim/3 has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please use the functions in the appropriate type-specific cache module.

    Asset Class                 | Module
    ----------------------------|--------------------------------
    Fonts                       | Scenic.Cache.Static.Font
    Font Metrics                | Scenic.Cache.Static.FontMetrics
    Textures (images in a fill) | Scenic.Cache.Static.Texture
    #{IO.ANSI.default_color()}
    """
  end

  @doc """
  This function is deprecated, please use the specific cache modules instead.

  | Asset Class   | Module  |
  | ------------- | -----|
  | Fonts      | [Scenic.Cache.Font](Scenic.Cache.Font.html) |
  | Font Metrics | [Scenic.Cache.FontMetrics](Scenic.Cache.FontMetrics.html) |
  | Textures (images in a fill) | [Scenic.Cache.Texture](Scenic.Cache.Texture.html) |
  """
  @deprecated "Use release in the appropriate cache module"
  def release(key, opts \\ [])
  def release(_, _) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.release/2 has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please use the functions in the appropriate type-specific cache module.

    Asset Class                 | Module
    ----------------------------|--------------------------------
    Fonts                       | Scenic.Cache.Static.Font
    Font Metrics                | Scenic.Cache.Static.FontMetrics
    Textures (images in a fill) | Scenic.Cache.Static.Texture
    #{IO.ANSI.default_color()}
    """
  end

  @doc """
  This function is deprecated, please use the specific cache modules instead.

  | Asset Class   | Module  |
  | ------------- | -----|
  | Fonts      | [Scenic.Cache.Font](Scenic.Cache.Font.html) |
  | Font Metrics | [Scenic.Cache.FontMetrics](Scenic.Cache.FontMetrics.html) |
  | Textures (images in a fill) | [Scenic.Cache.Texture](Scenic.Cache.Texture.html) |
  """
  @deprecated "Use status in the appropriate cache module"
  def status(key, scope \\ nil)
  def status(_, _) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.status/2 has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please use the functions in the appropriate type-specific cache module.

    Asset Class                 | Module
    ----------------------------|--------------------------------
    Fonts                       | Scenic.Cache.Static.Font
    Font Metrics                | Scenic.Cache.Static.FontMetrics
    Textures (images in a fill) | Scenic.Cache.Static.Texture
    #{IO.ANSI.default_color()}
    """
  end

  @doc """
  This function is deprecated, please use the specific cache modules instead.

  | Asset Class   | Module  |
  | ------------- | -----|
  | Fonts      | [Scenic.Cache.Font](Scenic.Cache.Font.html) |
  | Font Metrics | [Scenic.Cache.FontMetrics](Scenic.Cache.FontMetrics.html) |
  | Textures (images in a fill) | [Scenic.Cache.Texture](Scenic.Cache.Texture.html) |
  """
  @deprecated "Use keys in the appropriate cache module"
  def keys(scope \\ nil)
  def keys(_) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.keys/1 has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please use the functions in the appropriate type-specific cache module.

    Asset Class                 | Module
    ----------------------------|--------------------------------
    Fonts                       | Scenic.Cache.Static.Font
    Font Metrics                | Scenic.Cache.Static.FontMetrics
    Textures (images in a fill) | Scenic.Cache.Static.Texture
    #{IO.ANSI.default_color()}
    """
  end

  @doc """
  This function is deprecated, please use the specific cache modules instead.

  | Asset Class   | Module  |
  | ------------- | -----|
  | Fonts      | [Scenic.Cache.Font](Scenic.Cache.Font.html) |
  | Font Metrics | [Scenic.Cache.FontMetrics](Scenic.Cache.FontMetrics.html) |
  | Textures (images in a fill) | [Scenic.Cache.Texture](Scenic.Cache.Texture.html) |
  """
  @deprecated "Use member? in the appropriate cache module"
  def member?(key, scope \\ nil)
  def member?(_, _) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.member? has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please use the functions in the appropriate type-specific cache module.

    Asset Class                 | Module
    ----------------------------|--------------------------------
    Fonts                       | Scenic.Cache.Static.Font
    Font Metrics                | Scenic.Cache.Static.FontMetrics
    Textures (images in a fill) | Scenic.Cache.Static.Texture
    #{IO.ANSI.default_color()}
    """
  end
end
