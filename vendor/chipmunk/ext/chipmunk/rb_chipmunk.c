/* Copyright (c) 2007 Scott Lembcke
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <stdlib.h>

#include "chipmunk.h"

#include "ruby.h"
#include "rb_chipmunk.h"

VALUE m_Chipmunk;

ID id_parent;

static VALUE
rb_get_cp_bias_coef(VALUE self) {
  return rb_float_new(cp_bias_coef);
}

static VALUE
rb_set_cp_bias_coef(VALUE self, VALUE num) {
  cp_bias_coef = NUM2DBL(num);
  return num;
}

static VALUE
rb_get_cp_collision_slop(VALUE self) {
  return rb_float_new(cp_collision_slop);
}

static VALUE
rb_set_cp_collision_slop(VALUE self, VALUE num) {
  cp_collision_slop = NUM2DBL(num);
  return num;
}

static VALUE
rb_set_cp_contact_persistence(VALUE self, VALUE num) {
  cp_contact_persistence = NUM2UINT(num);
  return num;
}

static VALUE
rb_get_cp_contact_persistence(VALUE self) {
  return UINT2NUM(cp_contact_persistence);
}


static VALUE
rb_cpMomentForCircle(VALUE self, VALUE m, VALUE r1, VALUE r2, VALUE offset) {
  cpFloat i = cpMomentForCircle(NUM2DBL(m), NUM2DBL(r1), NUM2DBL(r2), *VGET(offset));
  return rb_float_new(i);
}

static VALUE
rb_cpMomentForSegment(VALUE self, VALUE m, VALUE v1, VALUE v2) {
  cpFloat i = cpMomentForSegment(NUM2DBL(m), *VGET(v1), *VGET(v2));
  return rb_float_new(i);
}

static VALUE
rb_cpMomentForPoly(VALUE self, VALUE m, VALUE arr, VALUE offset) {
  Check_Type(arr, T_ARRAY);
  long numVerts    = RARRAY_LEN(arr);
  VALUE *ary_ptr  = RARRAY_PTR(arr);
  cpVect verts[numVerts];

  for(long i = 0; i < numVerts; i++)
    verts[i] = *VGET(ary_ptr[i]);

  cpFloat inertia = cpMomentForPoly(NUM2DBL(m), numVerts, verts, *VGET(offset));
  return rb_float_new(inertia);
}

static VALUE
rb_cpMomentForBox(VALUE self, VALUE m, VALUE w, VALUE h) {
  cpFloat i = cpMomentForBox(NUM2DBL(m), NUM2DBL(w), NUM2DBL(h));
  return rb_float_new(i);
}

static VALUE
rb_cpAreaForCircle(VALUE self, VALUE r1, VALUE r2) {
  cpFloat i = cpAreaForCircle(NUM2DBL(r1), NUM2DBL(r2));
  return rb_float_new(i);
}

static VALUE
rb_cpAreaForSegment(VALUE self, VALUE v1, VALUE v2, VALUE r) {
  cpFloat i = cpAreaForSegment(*VGET(v1), *VGET(v2), NUM2DBL(r));
  return rb_float_new(i);
}

static VALUE
rb_cpAreaForPoly(VALUE self, VALUE arr) {
  Check_Type(arr, T_ARRAY);
  long numVerts   = RARRAY_LEN(arr);
  VALUE *ary_ptr = RARRAY_PTR(arr);
  cpVect verts[numVerts];

  for(long i = 0; i < numVerts; i++)
    verts[i] = *VGET(ary_ptr[i]);

  cpFloat area   = cpAreaForPoly(numVerts, verts);
  return rb_float_new(area);
}

static VALUE
rb_cpAreaForBox(VALUE self, VALUE w, VALUE h) {
  cpFloat i = NUM2DBL(w) * NUM2DBL(h);
  return rb_float_new(i);
}


static VALUE
rb_cpfclamp(VALUE self, VALUE f, VALUE min, VALUE max) {
  cpFloat result = cpfclamp(NUM2DBL(f), NUM2DBL(min), NUM2DBL(max));
  return rb_float_new(result);
}

static VALUE
rb_cpflerp(VALUE self, VALUE f1, VALUE f2, VALUE t) {
  cpFloat result = cpflerp(NUM2DBL(f1), NUM2DBL(f2), NUM2DBL(t));
  return rb_float_new(result);
}

static VALUE
rb_cpflerpconst(VALUE self, VALUE f1, VALUE f2, VALUE d) {
  cpFloat result = cpflerpconst(NUM2DBL(f1), NUM2DBL(f2), NUM2DBL(d));
  return rb_float_new(result);
}

static VALUE
rb_cpCentroidForPoly(VALUE self,  VALUE arr) {
  Check_Type(arr, T_ARRAY);
  long numVerts   = RARRAY_LEN(arr);
  VALUE *ary_ptr = RARRAY_PTR(arr);
  cpVect verts[numVerts];

  for(long i = 0; i < numVerts; i++)
    verts[i] = *VGET(ary_ptr[i]);

  return VNEW(cpCentroidForPoly(numVerts, verts));
}

static VALUE
rb_cpRecenterPoly(VALUE self,  VALUE arr) {
  Check_Type(arr, T_ARRAY);
  long numVerts   = RARRAY_LEN(arr);
  VALUE *ary_ptr = RARRAY_PTR(arr);
  cpVect verts[numVerts];

  for(long i = 0; i < numVerts; i++)
    verts[i] = *VGET(ary_ptr[i]);

  cpRecenterPoly(numVerts, verts);

  for(long i = 0; i < numVerts; i++)
    ary_ptr[i] = VNEW(verts[i]);
  return arr;
}




void
Init_chipmunk(void) {
  id_parent  = rb_intern("parent");

  cpInitChipmunk();



  m_Chipmunk = rb_define_module("CP");
  rb_define_module_function(m_Chipmunk, "bias_coef", rb_get_cp_bias_coef, 0);
  rb_define_module_function(m_Chipmunk, "bias_coef=", rb_set_cp_bias_coef, 1);
  rb_define_module_function(m_Chipmunk, "collision_slop", rb_get_cp_collision_slop, 0);
  rb_define_module_function(m_Chipmunk, "collision_slop=", rb_set_cp_collision_slop, 1);
  rb_define_module_function(m_Chipmunk, "contact_persistence", rb_get_cp_contact_persistence, 0);
  rb_define_module_function(m_Chipmunk, "contact_persistence=", rb_set_cp_contact_persistence, 1);



  rb_define_module_function(m_Chipmunk, "clamp", rb_cpfclamp, 3);
  rb_define_module_function(m_Chipmunk, "flerp", rb_cpflerp, 3);
  rb_define_module_function(m_Chipmunk, "flerpconst", rb_cpflerpconst, 3);

  rb_define_module_function(m_Chipmunk, "moment_for_circle", rb_cpMomentForCircle, 4);
  rb_define_module_function(m_Chipmunk, "moment_for_poly", rb_cpMomentForPoly, 3);
  rb_define_module_function(m_Chipmunk, "moment_for_segment", rb_cpMomentForSegment, 3);
  rb_define_module_function(m_Chipmunk, "moment_for_box", rb_cpMomentForBox, 3);

  rb_define_module_function(m_Chipmunk, "circle_moment", rb_cpMomentForCircle, 4);
  rb_define_module_function(m_Chipmunk, "poly_moment", rb_cpMomentForPoly, 3);
  rb_define_module_function(m_Chipmunk, "segment_moment", rb_cpMomentForSegment, 3);
  rb_define_module_function(m_Chipmunk, "box_moment", rb_cpMomentForBox, 3);


  rb_define_module_function(m_Chipmunk, "area_for_circle", rb_cpAreaForCircle, 2);
  rb_define_module_function(m_Chipmunk, "area_for_poly", rb_cpAreaForPoly, 1);
  rb_define_module_function(m_Chipmunk, "centroid_for_poly",
                            rb_cpCentroidForPoly, 1);
  rb_define_module_function(m_Chipmunk, "recenter_poly",
                            rb_cpRecenterPoly, 1);

  rb_define_module_function(m_Chipmunk, "area_for_segment", rb_cpAreaForSegment, 3);
  rb_define_module_function(m_Chipmunk, "area_for_box", rb_cpAreaForBox, 2);

  rb_define_module_function(m_Chipmunk, "circle_area", rb_cpAreaForCircle, 2);
  rb_define_module_function(m_Chipmunk, "poly_area", rb_cpAreaForPoly, 1);
  rb_define_module_function(m_Chipmunk, "segment_area", rb_cpAreaForSegment, 3);
  rb_define_module_function(m_Chipmunk, "box_area", rb_cpAreaForBox, 2);

  rb_define_const(m_Chipmunk, "ALL_LAYERS", UINT2NUM((unsigned int)CP_ALL_LAYERS));
  rb_define_const(m_Chipmunk, "NO_GROUP", UINT2NUM(CP_NO_GROUP));

  rb_eval_string("Float::INFINITY = 1.0/0.0 unless Float.const_defined? :INFINITY");
  rb_eval_string("CP::INFINITY = 1.0/0.0 unless CP.const_defined? :INFINITY");

  Init_cpVect();
  Init_cpBB();
  Init_cpBody();
  Init_cpShape();
  Init_cpConstraint();
  Init_cpSpace();
  Init_cpArbiter();
}
