//
//  Created by Boyd Multerer on 10/26/17.
//  Copyright © 2017 Kry10 Industries. All rights reserved.
//


#include <stdbool.h>
#include <erl_nif.h>

//---------------------------------------------------------
// get a double. cast if it is an integer
bool get_double_num(ErlNifEnv *env, ERL_NIF_TERM term, double* d ) {
  int   i;
  if ( enif_get_double(env, term, d) )  { return true; }
  if ( enif_get_int(env, term, &i) )    { *d = i; return true; }
  // no dice.
  return false;
}

//---------------------------------------------------------
// get a double. cast if it is an integer
bool get_float_num(ErlNifEnv *env, ERL_NIF_TERM term, float* f ) {
  double  d;
  int     i;
  if ( enif_get_double(env, term, &d) ) { *f = d; return true; }
  if ( enif_get_int(env, term, &i) )    { *f = i; return true; }
  // no dice.
  return false;
}
