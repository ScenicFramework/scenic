//
//  Created by Boyd Multerer on 2019-03-17.
//  Copyright © 2019 Kry10 Industries. All rights reserved.
//

#include <string.h>
#include <erl_nif.h>

//=============================================================================
// utilities

//=============================================================================
// Erlang NIF stuff from here down.

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_pixels_g(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  size;
  unsigned int  g;

  // get the parameters
  if ( !enif_get_uint(env, argv[0], &size) )   {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &g) )      {return enif_make_badarg(env);}

  // prepare the binary
  enif_alloc_binary( size, &pixels );

  // clear the pixels
  memset(pixels.data, g, size);

  return enif_make_binary( env, &pixels );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_pixels_ga(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  size;
  unsigned int  g;
  unsigned int  a;

  // get the parameters
  if ( !enif_get_uint(env, argv[0], &size) )   {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &g) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &a) )      {return enif_make_badarg(env);}

  // prepare the binary
  enif_alloc_binary( size, &pixels );

  // clear the pixels
  for( unsigned int i = 0; i < size; i += 2) {
    pixels.data[i] = g;
    pixels.data[i+1] = a;
  }

  return enif_make_binary( env, &pixels );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_pixels_rgb(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  size;
  unsigned int  r;
  unsigned int  g;
  unsigned int  b;

  // get the parameters
  if ( !enif_get_uint(env, argv[0], &size) )   {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &r) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &g) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[3], &b) )      {return enif_make_badarg(env);}

  // prepare the binary
  enif_alloc_binary( size, &pixels );

  // clear the pixels
  for( unsigned int i = 0; i < size; i += 3) {
    pixels.data[i] = r;
    pixels.data[i+1] = g;
    pixels.data[i+2] = b;
  }

  return enif_make_binary( env, &pixels );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_pixels_rgba(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  size;
  unsigned int  r;
  unsigned int  g;
  unsigned int  b;
  unsigned int  a;

  // get the parameters
  if ( !enif_get_uint(env, argv[0], &size) )   {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &r) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &g) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[3], &b) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[4], &a) )      {return enif_make_badarg(env);}

  // prepare the binary
  enif_alloc_binary( size, &pixels );

  // clear the pixels
  for( unsigned int i = 0; i < size; i += 4) {
    pixels.data[i] = r;
    pixels.data[i+1] = g;
    pixels.data[i+2] = b;
    pixels.data[i+3] = a;
  }

  return enif_make_binary( env, &pixels );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_get_g(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  pos;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) ) {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &pos) ) {return enif_make_badarg(env);}
  if ( pos >= pixels.size ) {return enif_make_badarg(env);}

  // return the value of g
  return enif_make_int( env, pixels.data[pos] );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_get_ga(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  pos;
  unsigned int  g;
  unsigned int  a;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &pos) )       {return enif_make_badarg(env);}
  if ( pos >= (pixels.size - 1) ) {return enif_make_badarg(env);}

  // get the values
  pos *= 2;
  g = pixels.data[pos];
  a = pixels.data[pos + 1];

  return enif_make_tuple2( env,
    enif_make_int( env, g ),
    enif_make_int( env, a )
  );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_get_rgb(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  pos;
  unsigned int  r;
  unsigned int  g;
  unsigned int  b;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &pos) )       {return enif_make_badarg(env);}
  if ( pos >= (pixels.size - 2) ) {return enif_make_badarg(env);}

  // get the values
  pos *= 3;
  r = pixels.data[pos];
  g = pixels.data[pos + 1];
  b = pixels.data[pos + 2];

  return enif_make_tuple3( env,
    enif_make_int( env, r ),
    enif_make_int( env, g ),
    enif_make_int( env, b )
  );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_get_rgba(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  pos;
  unsigned int  r;
  unsigned int  g;
  unsigned int  b;
  unsigned int  a;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &pos) )       {return enif_make_badarg(env);}
  if ( pos >= (pixels.size - 3) ) {return enif_make_badarg(env);}

  // get the values
  pos *= 4;
  r = pixels.data[pos];
  g = pixels.data[pos + 1];
  b = pixels.data[pos + 2];
  a = pixels.data[pos + 3];

  return enif_make_tuple4( env,
    enif_make_int( env, r ),
    enif_make_int( env, g ),
    enif_make_int( env, b ),
    enif_make_int( env, a )
  );
}


//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_put_g(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  pos;
  unsigned int  g;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &pos) )       {return enif_make_badarg(env);}
  if ( pos >= pixels.size ) {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &g) )      {return enif_make_badarg(env);}

  // put the value
  pixels.data[pos] = g;

  return enif_make_atom(env, "ok");;
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_put_ga(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  pos;
  unsigned int  g;
  unsigned int  a;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &pos) )       {return enif_make_badarg(env);}
  if ( pos >= (pixels.size - 1) ) {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &g) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[3], &a) )      {return enif_make_badarg(env);}

  // put the value
  pos *= 2;
  pixels.data[pos] = g;
  pixels.data[pos + 1] = a;

  return enif_make_atom(env, "ok");;
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_put_rgb(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  pos;
  unsigned int  r;
  unsigned int  g;
  unsigned int  b;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &pos) )       {return enif_make_badarg(env);}
  if ( pos >= (pixels.size - 2) ) {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &r) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[3], &g) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[4], &b) )      {return enif_make_badarg(env);}

  // put the value
  pos *= 3;
  pixels.data[pos] = r;
  pixels.data[pos + 1] = g;
  pixels.data[pos + 2] = b;

  return enif_make_atom(env, "ok");;
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_put_rgba(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  pos;
  unsigned int  r;
  unsigned int  g;
  unsigned int  b;
  unsigned int  a;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &pos) )       {return enif_make_badarg(env);}
  if ( pos >= (pixels.size - 3) ) {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &r) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[3], &g) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[4], &b) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[5], &a) )      {return enif_make_badarg(env);}

  // put the value
  pos *= 4;
  pixels.data[pos] = r;
  pixels.data[pos + 1] = g;
  pixels.data[pos + 2] = b;
  pixels.data[pos + 3] = a;

  return enif_make_atom(env, "ok");;
}




//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_clear_g(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  g;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &g) )      {return enif_make_badarg(env);}

  // clear the pixels
  memset(pixels.data, g, pixels.size);

  return enif_make_binary( env, &pixels );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_clear_ga(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  g;
  unsigned int  a;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &g) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &a) )      {return enif_make_badarg(env);}  

  // clear the pixels
  for( unsigned int i = 0; i < pixels.size; i += 2) {
    pixels.data[i] = g;
    pixels.data[i+1] = a;
  }

  return enif_make_binary( env, &pixels );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_clear_rgb(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  r;
  unsigned int  g;
  unsigned int  b;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &r) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &g) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[3], &b) )      {return enif_make_badarg(env);}

  // clear the pixels
  for( unsigned int i = 0; i < pixels.size; i += 3) {
    pixels.data[i] = r;
    pixels.data[i+1] = g;
    pixels.data[i+2] = b;
  }

  return enif_make_binary( env, &pixels );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_clear_rgba(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  r;
  unsigned int  g;
  unsigned int  b;
  unsigned int  a;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &r) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &g) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[3], &b) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[4], &a) )      {return enif_make_badarg(env);}

  // clear the pixels
  for( unsigned int i = 0; i < pixels.size; i += 4) {
    pixels.data[i] = r;
    pixels.data[i+1] = g;
    pixels.data[i+2] = b;
    pixels.data[i+3] = a;
  }

  return enif_make_binary( env, &pixels );
}


//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_g_to_rgba(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  g_pixels;
  ErlNifBinary  rgba_pixels;
  unsigned int  pix_count;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &g_pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &pix_count) )      {return enif_make_badarg(env);}

  // create the destination binary
  enif_alloc_binary( pix_count * 4, &rgba_pixels );

  // clear the pixels
  unsigned int di;
  for( unsigned int i = 0; i < pix_count; i ++) {
    di = i * 4;
    rgba_pixels.data[di] = g_pixels.data[i];
    rgba_pixels.data[di+1] = g_pixels.data[i];
    rgba_pixels.data[di+2] = g_pixels.data[i];
    rgba_pixels.data[di+3] = 0xff;
  }

  return enif_make_binary( env, &rgba_pixels );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_ga_to_rgba(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  ga_pixels;
  ErlNifBinary  rgba_pixels;
  unsigned int  pix_count;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &ga_pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &pix_count) )      {return enif_make_badarg(env);}

  // create the destination binary
  enif_alloc_binary( pix_count * 4, &rgba_pixels );

  // clear the pixels
  unsigned int di;
  unsigned int si;
  for( unsigned int i = 0; i < pix_count; i ++) {
    si = i * 2;
    di = i * 4;
    rgba_pixels.data[di] = ga_pixels.data[si];
    rgba_pixels.data[di+1] = ga_pixels.data[si];
    rgba_pixels.data[di+2] = ga_pixels.data[si];
    rgba_pixels.data[di+3] = ga_pixels.data[si + 1];
  }

  return enif_make_binary( env, &rgba_pixels );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_rgb_to_rgba(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  rgb_pixels;
  ErlNifBinary  rgba_pixels;
  unsigned int  pix_count;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &rgb_pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &pix_count) )      {return enif_make_badarg(env);}

  // create the destination binary
  enif_alloc_binary( pix_count * 4, &rgba_pixels );

  // clear the pixels
  unsigned int di;
  unsigned int si;
  for( unsigned int i = 0; i < pix_count; i ++) {
    si = i * 3;
    di = i * 4;
    rgba_pixels.data[di] = rgb_pixels.data[si];
    rgba_pixels.data[di + 1] = rgb_pixels.data[si + 1];
    rgba_pixels.data[di + 2] = rgb_pixels.data[si + 2];
    rgba_pixels.data[di + 3] = 0xff;
  }

  return enif_make_binary( env, &rgba_pixels );
}


//=============================================================================
// erl housekeeping. This is the list of functions available to the erl side

static ErlNifFunc nif_funcs[] = {
  // {erl_function_name, erl_function_arity, c_function}
  {"nif_pixels",          2, nif_pixels_g,      0},
  {"nif_pixels",          3, nif_pixels_ga,     0},
  {"nif_pixels",          4, nif_pixels_rgb,    0},
  {"nif_pixels",          5, nif_pixels_rgba,   0},
  {"nif_get_g",           2, nif_get_g,         0},
  {"nif_get_ga",          2, nif_get_ga,        0},
  {"nif_get_rgb",         2, nif_get_rgb,       0},
  {"nif_get_rgba",        2, nif_get_rgba,      0},
  {"nif_put",             3, nif_put_g,         0},
  {"nif_put",             4, nif_put_ga,        0},
  {"nif_put",             5, nif_put_rgb,       0},
  {"nif_put",             6, nif_put_rgba,      0},
  {"nif_clear",           2, nif_clear_g,       0},
  {"nif_clear",           3, nif_clear_ga,      0},
  {"nif_clear",           4, nif_clear_rgb,     0},
  {"nif_clear",           5, nif_clear_rgba,    0},
  {"nif_g_to_rgba",       2, nif_g_to_rgba,     0},
  {"nif_ga_to_rgba",      2, nif_ga_to_rgba,    0},
  {"nif_rgb_to_rgba",     2, nif_rgb_to_rgba,   0}
};

ERL_NIF_INIT(Elixir.Scenic.Utilities.Texture, nif_funcs, NULL, NULL, NULL, NULL)