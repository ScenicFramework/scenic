//
//  Created by Boyd Multerer on 2021-04-19
//  Copyright © 2021 Kry10 Limited. All rights reserved.
//

#include <string.h>
#include <erl_nif.h>

//=============================================================================
// utilities

//=============================================================================
// Erlang NIF stuff from here down.

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
  unsigned int  size;
  unsigned int  g;
  unsigned int  a;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &g) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &a) )      {return enif_make_badarg(env);}  

  // clear the pixels
  size = pixels.size;
  for( unsigned int i = 0; i < size; i += 2) {
    pixels.data[i] = g;
    pixels.data[i+1] = a;
  }

  return enif_make_binary( env, &pixels );
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_clear_rgb(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pixels;
  unsigned int  size;
  unsigned int  r;
  unsigned int  g;
  unsigned int  b;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pixels) )    {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &r) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &g) )      {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[3], &b) )      {return enif_make_badarg(env);}

  // clear the pixels
  size = pixels.size;
  for( unsigned int i = 0; i < size; i += 3) {
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
  unsigned int  size;
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
  size = pixels.size;
  for( unsigned int i = 0; i < size; i += 4) {
    pixels.data[i] = r;
    pixels.data[i+1] = g;
    pixels.data[i+2] = b;
    pixels.data[i+3] = a;
  }

  return enif_make_binary( env, &pixels );
}


//=============================================================================
// erl housekeeping. This is the list of functions available to the erl side

static ErlNifFunc nif_funcs[] = {
  // {erl_function_name, erl_function_arity, c_function}
  {"nif_put",             3, nif_put_g,         0},
  {"nif_put",             4, nif_put_ga,        0},
  {"nif_put",             5, nif_put_rgb,       0},
  {"nif_put",             6, nif_put_rgba,      0},
  {"nif_clear",           2, nif_clear_g,       0},
  {"nif_clear",           3, nif_clear_ga,      0},
  {"nif_clear",           4, nif_clear_rgb,     0},
  {"nif_clear",           5, nif_clear_rgba,    0},
};

ERL_NIF_INIT(Elixir.Scenic.Assets.Stream.Texture, nif_funcs, NULL, NULL, NULL, NULL)