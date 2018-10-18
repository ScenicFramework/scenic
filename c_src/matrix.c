//
//  Created by Boyd Multerer
//  Copyright © 2017 Kry10 Industries. All rights reserved.
//

// native matrix math functions.

#include <stdbool.h>
#include <string.h>
#include <math.h>
#include <erl_nif.h>

// #include "erl_utils.h"

static const float matrix_identity[16] = {
  1.0f, 0.0f, 0.0f, 0.0f,
  0.0f, 1.0f, 0.0f, 0.0f,
  0.0f, 0.0f, 1.0f, 0.0f,
  0.0f, 0.0f, 0.0f, 1.0f
  };


#define   MATRIX_SIZE     (sizeof(float) * 16)

//=============================================================================
// utilities

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
// get a float. cast if it is an integer
bool get_float_num(ErlNifEnv *env, ERL_NIF_TERM term, float* f ) {
  double  d;
  int     i;
  if ( enif_get_double(env, term, &d) ) { *f = d; return true; }
  if ( enif_get_int(env, term, &i) )    { *f = i; return true; }
  // no dice.
  return false;
}

//=============================================================================
// matrix math

//---------------------------------------------------------
bool matrix_close(float a[], float b[], double tolerance) {
  double t = fabs(tolerance);
  for(int i = 0; i < 16; i++ ) {
    if (fabs(a[i] - b[i]) > t) {
      return false;
    }
  };
  return true;
}

//---------------------------------------------------------
void matrix_add(float a[], float b[], float c[]) {
  for(int i = 0; i < 16; i++ ) { c[i] = a[i] + b[i]; };
}

//---------------------------------------------------------
void matrix_subtract(float a[], float b[], float c[]) {
  for(int i = 0; i < 16; i++ ) { c[i] = a[i] - b[i]; };
}

//---------------------------------------------------------
void matrix_multiply(float a[], float b[], float c[]) {
  c[0]  = (a[0]  * b[0]) + (a[1]  * b[4]) + (a[2] * b[8])   + (a[3] * b[12]);
  c[1]  = (a[0]  * b[1]) + (a[1]  * b[5]) + (a[2] * b[9])   + (a[3] * b[13]);
  c[2]  = (a[0]  * b[2]) + (a[1]  * b[6]) + (a[2] * b[10])  + (a[3] * b[14]);
  c[3]  = (a[0]  * b[3]) + (a[1]  * b[7]) + (a[2] * b[11])  + (a[3] * b[15]);

  c[4]  = (a[4]  * b[0]) + (a[5]  * b[4]) + (a[6] * b[8])   + (a[7] * b[12]);
  c[5]  = (a[4]  * b[1]) + (a[5]  * b[5]) + (a[6] * b[9])   + (a[7] * b[13]);
  c[6]  = (a[4]  * b[2]) + (a[5]  * b[6]) + (a[6] * b[10])  + (a[7] * b[14]);
  c[7]  = (a[4]  * b[3]) + (a[5]  * b[7]) + (a[6] * b[11])  + (a[7] * b[15]);

  c[8]  = (a[8]  * b[0]) + (a[9]  * b[4]) + (a[10] * b[8])  + (a[11] * b[12]);
  c[9]  = (a[8]  * b[1]) + (a[9]  * b[5]) + (a[10] * b[9])  + (a[11] * b[13]);
  c[10] = (a[8]  * b[2]) + (a[9]  * b[6]) + (a[10] * b[10]) + (a[11] * b[14]);
  c[11] = (a[8]  * b[3]) + (a[9]  * b[7]) + (a[10] * b[11]) + (a[11] * b[15]);

  c[12] = (a[12] * b[0]) + (a[13] * b[4]) + (a[14] * b[8])  + (a[15] * b[12]);
  c[13] = (a[12] * b[1]) + (a[13] * b[5]) + (a[14] * b[9])  + (a[15] * b[13]);
  c[14] = (a[12] * b[2]) + (a[13] * b[6]) + (a[14] * b[10]) + (a[15] * b[14]);
  c[15] = (a[12] * b[3]) + (a[13] * b[7]) + (a[14] * b[11]) + (a[15] * b[15]);
}

//---------------------------------------------------------
void matrix_multiply_scalar(float a[], float s, float c[]) {
  for(int i = 0; i < 16; i++ ) { c[i] = a[i] * s; };
}

//---------------------------------------------------------
void matrix_divide_scalar(float a[], float s, float c[]) {
  for(int i = 0; i < 16; i++ ) { c[i] = a[i] / s; };
}

//---------------------------------------------------------
float matrix_determinant(float a[]) {
  return (a[0]  * a[5]  * a[10] * a[15]) + (a[0]  * a[9]  * a[14] * a[7])  +
  (a[0]  * a[13] * a[6]  * a[11]) + (a[4]  * a[1]  * a[14] * a[11]) +
  (a[4]  * a[9]  * a[2]  * a[15]) + (a[4]  * a[13] * a[10] * a[3])  +
  (a[8]  * a[1]  * a[6]  * a[15]) + (a[8]  * a[5]  * a[14] * a[3])  +
  (a[8]  * a[13] * a[2]  * a[7])  + (a[12] * a[1]  * a[10] * a[7])  +
  (a[12] * a[5]  * a[2]  * a[11]) + (a[12] * a[9]  * a[6]  * a[3])  -
  (a[0]  * a[5]  * a[14] * a[11]) - (a[0]  * a[9]  * a[6]  * a[15]) -
  (a[0]  * a[13] * a[10] * a[7])  - (a[4]  * a[1]  * a[10] * a[15]) -
  (a[4]  * a[9]  * a[14] * a[3])  - (a[4]  * a[13] * a[2]  * a[11]) - 
  (a[8]  * a[1]  * a[14] * a[7])  - (a[8]  * a[5]  * a[2]  * a[15]) -
  (a[8]  * a[13] * a[6]  * a[3])  - (a[12] * a[1]  * a[6]  * a[11]) -
  (a[12] * a[5]  * a[10] * a[3])  - (a[12] * a[9]  * a[2]  * a[7]);
}

//---------------------------------------------------------
void matrix_transpose(float a[], float c[]) {
  c[0] = a[0];
  c[1] = a[4];
  c[2] = a[8];
  c[3] = a[12];

  c[4] = a[1];
  c[5] = a[5];
  c[6] = a[9];
  c[7] = a[13];

  c[8] = a[2];
  c[9] = a[6];
  c[10] = a[10];
  c[11] = a[14];

  c[12] = a[3];
  c[13] = a[7];
  c[14] = a[11];
  c[15] = a[15];
}

//---------------------------------------------------------
void matrix_adjugate(float a[], float c[]) {
//  float b[16];

  c[0]  = (a[5]*a[10]*a[15]) + (a[9]*a[14]*a[7]) + (a[13]*a[6]*a[11]) - (a[5]*a[14]*a[11]) - (a[9]*a[6]*a[15]) - (a[13]*a[10]*a[7]);
  c[4]  = (a[4]*a[14]*a[11]) + (a[8]*a[6]*a[15]) + (a[12]*a[10]*a[7]) - (a[4]*a[10]*a[15]) - (a[8]*a[14]*a[7]) - (a[12]*a[6]*a[11]);
  c[8]  = (a[4]*a[9]*a[15])  + (a[8]*a[13]*a[7]) + (a[12]*a[5]*a[11]) - (a[4]*a[13]*a[11]) - (a[8]*a[5]*a[15]) - (a[12]*a[9]*a[7]);
  c[12] = (a[4]*a[13]*a[10]) + (a[8]*a[5]*a[14]) + (a[12]*a[9]*a[6])  - (a[4]*a[9]*a[14])  - (a[8]*a[13]*a[6]) - (a[12]*a[5]*a[10]);

  c[1]  = (a[1]*a[14]*a[11]) + (a[9]*a[2]*a[15]) + (a[13]*a[10]*a[3]) - (a[1]*a[10]*a[15]) - (a[9]*a[14]*a[3]) - (a[13]*a[2]*a[11]);
  c[5]  = (a[0]*a[10]*a[15]) + (a[8]*a[14]*a[3]) + (a[12]*a[2]*a[11]) - (a[0]*a[14]*a[11]) - (a[8]*a[2]*a[15]) - (a[12]*a[10]*a[3]);
  c[9]  = (a[0]*a[13]*a[11]) + (a[8]*a[1]*a[15]) + (a[12]*a[9]*a[3])  - (a[0]*a[9]*a[15])  - (a[8]*a[13]*a[3]) - (a[12]*a[1]*a[11]);
  c[13] = (a[0]*a[9]*a[14])  + (a[8]*a[13]*a[2]) + (a[12]*a[1]*a[10]) - (a[0]*a[13]*a[10]) - (a[8]*a[1]*a[14]) - (a[12]*a[9]*a[2]);

  c[2]  = (a[1]*a[6]*a[15])  + (a[5]*a[14]*a[3]) + (a[13]*a[2]*a[7])  - (a[1]*a[14]*a[7])  - (a[5]*a[2]*a[15]) - (a[13]*a[6]*a[3]);
  c[6]  = (a[0]*a[14]*a[7])  + (a[4]*a[2]*a[15]) + (a[12]*a[6]*a[3])  - (a[0]*a[6]*a[15])  - (a[4]*a[14]*a[3]) - (a[12]*a[2]*a[7]);
  c[10] = (a[0]*a[5]*a[15])  + (a[4]*a[13]*a[3]) + (a[12]*a[1]*a[7])  - (a[0]*a[13]*a[7])  - (a[4]*a[1]*a[15]) - (a[12]*a[5]*a[3]);
  c[14] = (a[0]*a[13]*a[6])  + (a[4]*a[1]*a[14]) + (a[12]*a[5]*a[2])  - (a[0]*a[5]*a[14])  - (a[4]*a[13]*a[2]) - (a[12]*a[1]*a[6]);

  c[3]  = (a[1]*a[10]*a[7])  + (a[5]*a[2]*a[11]) + (a[9]*a[6]*a[3])   - (a[1]*a[6]*a[11])  - (a[5]*a[10]*a[3]) - (a[9]*a[2]*a[7]);
  c[7]  = (a[0]*a[6]*a[11])  + (a[4]*a[10]*a[3]) + (a[8]*a[2]*a[7])   - (a[0]*a[10]*a[7])  - (a[4]*a[2]*a[11]) - (a[8]*a[6]*a[3]);
  c[11] = (a[0]*a[9]*a[7])   + (a[4]*a[1]*a[11]) + (a[8]*a[5]*a[3])   - (a[0]*a[5]*a[11])  - (a[4]*a[9]*a[3])  - (a[8]*a[1]*a[7]);
  c[15] = (a[0]*a[5]*a[10])  + (a[4]*a[9]*a[2])  + (a[8]*a[1]*a[6])   - (a[0]*a[9]*a[6])   - (a[4]*a[1]*a[10]) - (a[8]*a[5]*a[2]);
}

//---------------------------------------------------------
void matrix_project_vector2(float mx[], float* x, float* y) {
  float mxv[16] = {
    1.0f, 0.0f, 0.0f, *x,
    0.0f, 1.0f, 0.0f, *y,
    0.0f, 0.0f, 1.0f, 0.0f,
    0.0f, 0.0f, 0.0f, 1.0f
  };
  float mx_out[16];

  // do the multiply
  matrix_multiply(mx, mxv, mx_out);

  // extract the results
  *x = mx_out[3];
  *y = mx_out[7];
}

//---------------------------------------------------------
void matrix_project_vector3(float mx[], float* x, float* y, float* z) {
  float mxv[16] = {
    1.0f, 0.0f, 0.0f, *x,
    0.0f, 1.0f, 0.0f, *y,
    0.0f, 0.0f, 1.0f, *z,
    0.0f, 0.0f, 0.0f, 1.0f
  };
  float mx_out[16];

  // do the multiply
  matrix_multiply(mx, mxv, mx_out);

  // extract the results
  *x = mx_out[3];
  *y = mx_out[7];
  *z = mx_out[11];
}

//=============================================================================
// Erlang NIF stuff from here down.

//-----------------------------------------------------------------------------
// determine true/false if two matrices are close the the same values. Close
// means all values are within the given tolerance of each other

static ERL_NIF_TERM
nif_close(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary      a_term, b_term;

  float *   a;
  float *   b;
  double  tolerance;

  // retrieve the a and b matrices
  if ( !enif_inspect_binary(env, argv[0], &a_term) )    {return enif_make_badarg(env);}
  if ( a_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  a = (float*) a_term.data;

  if ( !enif_inspect_binary(env, argv[1], &b_term) )    {return enif_make_badarg(env);}
  if ( b_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  b = (float*) b_term.data;

  if ( !enif_get_double(env, argv[2], &tolerance) )     {return enif_make_badarg(env);}

  // return the result
  if ( matrix_close(a, b, tolerance) ) {
    return enif_make_atom(env, "true");
  }else{
    return enif_make_atom(env, "false");
  }
}

//-----------------------------------------------------------------------------
// add two matrices together. result is stored in a new matrix

static ERL_NIF_TERM
nif_add(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary      a_term, b_term;
  ERL_NIF_TERM      result;

  float *           a;
  float *           b;
  float *           c;

  // retrieve the a and b matrices
  if ( !enif_inspect_binary(env, argv[0], &a_term) )    {return enif_make_badarg(env);}
  if ( a_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  a = (float*) a_term.data;

  if ( !enif_inspect_binary(env, argv[1], &b_term) )    {return enif_make_badarg(env);}
  if ( b_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  b = (float*) b_term.data;

  // create a binary matrix to hold the result
  c = (float*)enif_make_new_binary(env, sizeof(float) * 16, &result);

  // add the matrices together
  matrix_add( a, b, c );

  // return the result
  return result;
}

//-----------------------------------------------------------------------------
// subtract two matrices (b from a). result is stored in a new matrix

static ERL_NIF_TERM
nif_subtract(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary      a_term, b_term;
  ERL_NIF_TERM      result;

  float *           a;
  float *           b;
  float *           c;

  // retrieve the a and b matrices
  if ( !enif_inspect_binary(env, argv[0], &a_term) )    {return enif_make_badarg(env);}
  if ( a_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  a = (float*) a_term.data;

  if ( !enif_inspect_binary(env, argv[1], &b_term) )    {return enif_make_badarg(env);}
  if ( b_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  b = (float*) b_term.data;

  // create a binary matrix to hold the result
  c = (float*)enif_make_new_binary(env, sizeof(float) * 16, &result);

  // subtract the matrices
  matrix_subtract( a, b, c );

  // return the result
  return result;
}

//-----------------------------------------------------------------------------
// multiply two matrices together. result is stored in a new matrix

static ERL_NIF_TERM
nif_multiply(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary      a_term, b_term;
  ERL_NIF_TERM      result;

  float *           a;
  float *           b;
  float *           c;

  // retrieve the a and b matrices
  if ( !enif_inspect_binary(env, argv[0], &a_term) )    {return enif_make_badarg(env);}
  if ( a_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  a = (float*) a_term.data;

  if ( !enif_inspect_binary(env, argv[1], &b_term) )    {return enif_make_badarg(env);}
  if ( b_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  b = (float*) b_term.data;

  // create a binary matrix to hold the result
  c = (float*)enif_make_new_binary(env, sizeof(float) * 16, &result);

  // multiply the matrices together
  matrix_multiply(a, b, c);

  // return the result
  return result;
}

//-----------------------------------------------------------------------------
// multiply two matrices together. result is stored in a new matrix

static ERL_NIF_TERM
nif_multiply_list(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ERL_NIF_TERM      head_term, tail_term;
  ErlNifBinary      matrix_term;
  ERL_NIF_TERM      result;

  float *           c;
  unsigned          list_len;
  unsigned          i;
  int               src = 1;
  int               dst = 0;

  float             product[2][16];

  // set the tail_term to just be the list itself
  tail_term = argv[0];

  // get the length of the list. Bail early if this fails (not a list)
  if ( !enif_get_list_length(env, tail_term, &list_len) )    {return enif_make_badarg(env);}

  // initilize c to identity
  memcpy( product[0], matrix_identity, MATRIX_SIZE );

  // loop the list, multiplying each array into c
  for (i = 0; i < list_len; i++ ) {
    // get the head and tail
    enif_get_list_cell(env, tail_term, &head_term, &tail_term);

    // get the matrix from the head
    if ( !enif_inspect_binary(env, head_term, &matrix_term) ) {return enif_make_badarg(env);}
    if ( matrix_term.size != MATRIX_SIZE )                    {return enif_make_badarg(env);}

    // swap source and dest
    src = (src == 0) ? 1 : 0;
    dst = (dst == 0) ? 1 : 0;

    // multiply in
    matrix_multiply(product[src], (float*) matrix_term.data, product[dst]);
  }

  // create a binary matrix to hold the result
  c = (float*)enif_make_new_binary(env, sizeof(float) * 16, &result);
  // copy the last dst matrix into the result
  memcpy( c, product[dst], MATRIX_SIZE );

  // return the result
  return result;
}

//-----------------------------------------------------------------------------
// multiply a matrix by a scalar

static ERL_NIF_TERM
nif_multiply_scalar(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary      a_term;
  ERL_NIF_TERM      result;
  double            dbl;

  float *           a;
  float *           c;

  // retrieve the a matrix
  if ( !enif_inspect_binary(env, argv[0], &a_term) )    {return enif_make_badarg(env);}
  if ( a_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  a = (float*) a_term.data;

  // retrieve the scalar
  if ( !enif_get_double(env, argv[1], &dbl) )           {return enif_make_badarg(env);}

  // create a binary matrix to hold the result
  c = (float*)enif_make_new_binary(env, sizeof(float) * 16, &result);

  // multiply the matrix by the scalar
  matrix_multiply_scalar(a, (float)dbl, c);

  // return the result
  return result;
}

//-----------------------------------------------------------------------------
// divide a matrix by a scalar

static ERL_NIF_TERM
nif_divide_scalar(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary      a_term;
  ERL_NIF_TERM      result;
  double            dbl;

  float *           a;
  float *           c;

  // retrieve the a matrix
  if ( !enif_inspect_binary(env, argv[0], &a_term) )    {return enif_make_badarg(env);}
  if ( a_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  a = (float*) a_term.data;

  // retrieve the scalar
  if ( !enif_get_double(env, argv[1], &dbl) )           {return enif_make_badarg(env);}

  // create a binary matrix to hold the result
  c = (float*)enif_make_new_binary(env, sizeof(float) * 16, &result);

  // divide the matrix by the scalar
  matrix_divide_scalar(a, (float)dbl, c);

  // return the result
  return result;
}

//-----------------------------------------------------------------------------
// calculate the scalar determinant

static ERL_NIF_TERM
nif_determinant(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary      a_term;
  float *           a;

  // retrieve the a matrix
  if ( !enif_inspect_binary(env, argv[0], &a_term) )    {return enif_make_badarg(env);}
  if ( a_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  a = (float*) a_term.data;

  // calc the determinant
  // return the result
  return enif_make_double(
    env,
    (double)matrix_determinant(a)
  );
}

//-----------------------------------------------------------------------------
// calculate the transpose matrix

static ERL_NIF_TERM
nif_transpose(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary      a_term;
  ERL_NIF_TERM      result;
  float *           a;
  float *           c;

  // retrieve the a matrix
  if ( !enif_inspect_binary(env, argv[0], &a_term) )    {return enif_make_badarg(env);}
  if ( a_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  a = (float*) a_term.data;

  // create a binary matrix to hold the result
  c = (float*)enif_make_new_binary(env, sizeof(float) * 16, &result);

  // calc the transpose
  matrix_transpose(a, c);

  // return the result
  return result;
}

//-----------------------------------------------------------------------------
// calculate the transpose matrix

static ERL_NIF_TERM
nif_adjugate(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary      a_term;
  ERL_NIF_TERM      result;
  float *           a;
  float *           c;

  // retrieve the a matrix
  if ( !enif_inspect_binary(env, argv[0], &a_term) )    {return enif_make_badarg(env);}
  if ( a_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  a = (float*) a_term.data;

  // create a binary matrix to hold the result
  c = (float*)enif_make_new_binary(env, sizeof(float) * 16, &result);

  // calc the transpose
  matrix_adjugate(a, c);

  // return the result
  return result;
}

//-----------------------------------------------------------------------------
// project a 2d vector by a matrix
static ERL_NIF_TERM
nif_project_vector2(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary      mx_term;
  float *           mx;
  float             x, y;

  // get the a matrix
  if ( !enif_inspect_binary(env, argv[0], &mx_term) )    {return enif_make_badarg(env);}
  if ( mx_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  mx = (float*) mx_term.data;

  // get the x and y of the vector
  if ( !get_float_num(env, argv[1], &x) )               {return enif_make_badarg(env);}
  if ( !get_float_num(env, argv[2], &y) )               {return enif_make_badarg(env);}

  // project the vector
  matrix_project_vector2( mx, &x, &y );

  // return the result
  return enif_make_tuple2(
    env,
    enif_make_double(env, x),
    enif_make_double(env, y)
  );
}

//-----------------------------------------------------------------------------
// project a packed 2d vector binary by a matrix
typedef struct { float x; float y; } vector2_f;
static ERL_NIF_TERM
nif_project_vector2s(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ERL_NIF_TERM      result;
  ErlNifBinary      mx_term;
  ErlNifBinary      v_in_term;
  float *           mx;
  int               vector_count;
  vector2_f*        v_in;
  vector2_f*        v_out;
  float             x, y;

  // get the matrix
  if ( !enif_inspect_binary(env, argv[0], &mx_term) )    {return enif_make_badarg(env);}
  if ( mx_term.size != MATRIX_SIZE )                     {return enif_make_badarg(env);}
  mx = (float*) mx_term.data;

  // get the vectors
  if ( !enif_inspect_binary(env, argv[1], &v_in_term) )  {return enif_make_badarg(env);}
  if ( (v_in_term.size % (sizeof(float)*2)) != 0 )       {return enif_make_badarg(env);}
  vector_count = v_in_term.size / (sizeof(float)*2);
  v_in = (vector2_f*)v_in_term.data;

  // allocate the outgoing vector binary
  v_out = (vector2_f*)enif_make_new_binary(env, v_in_term.size, &result);

  // fill in the answers
  for ( int i = 0; i < vector_count; i++ ) {
    x = v_in[i].x;
    y = v_in[i].y;
    matrix_project_vector2( mx, &x, &y );
    v_out[i].x = x;
    v_out[i].y = y;
  }

  // return the resulting binary
  return result;
}

//=============================================================================
// erl housekeeping. This is the list of functions available to the erl side

static ErlNifFunc nif_funcs[] = {
  // {erl_function_name, erl_function_arity, c_function}
//  {"do_put", 4, nif_put},
  {"nif_close",             3, nif_close,           0},
  {"nif_add",               2, nif_add,             0},
  {"nif_subtract",          2, nif_subtract,        0},
  {"nif_multiply",          2, nif_multiply,        0},
  {"nif_multiply_list",     1, nif_multiply_list,   0},
  {"nif_multiply_scalar",   2, nif_multiply_scalar, 0},
  {"nif_divide_scalar",     2, nif_divide_scalar,   0},
  {"nif_determinant",       1, nif_determinant,     0},
  {"nif_transpose",         1, nif_transpose,       0},
  {"nif_adjugate",          1, nif_adjugate,        0},
  {"nif_project_vector2",   3, nif_project_vector2, 0},
  {"nif_project_vector2s",  2, nif_project_vector2s, 0},
  // {"nif_project_vector3",   4, nif_project_vector3, 0},
  // {"nif_project_vector3s",  2, nif_project_vector3s, 0},
};

ERL_NIF_INIT(Elixir.Scenic.Math.Matrix, nif_funcs, NULL, NULL, NULL, NULL)
