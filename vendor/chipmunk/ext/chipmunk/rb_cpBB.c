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

VALUE c_cpBB;

static VALUE
BBNEW(cpBB bb) {
  cpBB *ptr = malloc(sizeof(cpBB));
  *ptr = bb;
  return Data_Wrap_Struct(c_cpBB, NULL, free, ptr);
}

static VALUE
rb_cpBBAlloc(VALUE klass) {
  cpBB *bb = calloc(sizeof(cpBB), 1);
  return Data_Wrap_Struct(klass, NULL, free, bb);
}

static VALUE
rb_cpBBInitialize(VALUE self, VALUE l, VALUE b, VALUE r, VALUE t) {
  cpBB *bb = BBGET(self);
  bb->l = NUM2DBL(l);
  bb->b = NUM2DBL(b);
  bb->r = NUM2DBL(r);
  bb->t = NUM2DBL(t);

  return self;
}

static VALUE
rb_cpBBintersects(VALUE self, VALUE other) {
  int value = cpBBintersects(*BBGET(self), *BBGET(other));
  return value ? Qtrue : Qfalse;
}

static VALUE
rb_cpBBcontainsBB(VALUE self, VALUE other) {
  int value = cpBBcontainsBB(*BBGET(self), *BBGET(other));
  return value ? Qtrue : Qfalse;
}

static VALUE
rb_cpBBcontainsVect(VALUE self, VALUE other) {
  int value = cpBBcontainsVect(*BBGET(self), *VGET(other));
  return value ? Qtrue : Qfalse;
}

static VALUE
rb_cpBBcontains(VALUE self, VALUE other) {
  if (rb_class_of(other) == c_cpBB) {
    return rb_cpBBcontainsBB(self, other);
  } else if (rb_class_of(other) == c_cpVect) {
    return rb_cpBBcontainsVect(self, other);
  }
  rb_raise(rb_eArgError, "contains works only with a BB or A Vect2 argument");
  return Qnil;
}

static VALUE
rb_cpBBClampVect(VALUE self, VALUE v) {
  return VNEW(cpBBClampVect(*BBGET(self), *VGET(v)));
}

static VALUE
rb_cpBBWrapVect(VALUE self, VALUE v) {
  return VNEW(cpBBWrapVect(*BBGET(self), *VGET(v)));
}

static VALUE
rb_cpBBGetL(VALUE self) {
  return rb_float_new(BBGET(self)->l);
}

static VALUE
rb_cpBBGetB(VALUE self) {
  return rb_float_new(BBGET(self)->b);
}

static VALUE
rb_cpBBGetR(VALUE self) {
  return rb_float_new(BBGET(self)->r);
}

static VALUE
rb_cpBBGetT(VALUE self) {
  return rb_float_new(BBGET(self)->t);
}

static VALUE
rb_cpBBSetL(VALUE self, VALUE val) {
  BBGET(self)->l = NUM2DBL(val);
  return val;
}

static VALUE
rb_cpBBSetB(VALUE self, VALUE val) {
  BBGET(self)->b = NUM2DBL(val);
  return val;
}

static VALUE
rb_cpBBSetR(VALUE self, VALUE val) {
  BBGET(self)->r = NUM2DBL(val);
  return val;
}

static VALUE
rb_cpBBSetT(VALUE self, VALUE val) {
  BBGET(self)->t = NUM2DBL(val);
  return val;
}

static VALUE
rb_cpBBToString(VALUE self) {
  char str[256];
  cpBB *bb = BBGET(self);

  sprintf(str, "#<CP::BB:(% .3f, % .3f) -> (% .3f, % .3f)>", bb->l, bb->b, bb->r, bb->t);

  return rb_str_new2(str);
}

static VALUE
rb_cpBBmerge(VALUE self, VALUE other) {
  return BBNEW(cpBBmerge(*BBGET(self), *BBGET(other)));
}

static VALUE
rb_cpBBexpand(VALUE self, VALUE other) {
  return BBNEW(cpBBexpand(*BBGET(self), *VGET(other)));
}


void
Init_cpBB(void) {
  c_cpBB = rb_define_class_under(m_Chipmunk, "BB", rb_cObject);
  rb_define_alloc_func(c_cpBB, rb_cpBBAlloc);
  rb_define_method(c_cpBB, "initialize", rb_cpBBInitialize, 4);

  rb_define_method(c_cpBB, "l", rb_cpBBGetL, 0);
  rb_define_method(c_cpBB, "b", rb_cpBBGetB, 0);
  rb_define_method(c_cpBB, "r", rb_cpBBGetR, 0);
  rb_define_method(c_cpBB, "t", rb_cpBBGetT, 0);

  rb_define_method(c_cpBB, "l=", rb_cpBBSetL, 1);
  rb_define_method(c_cpBB, "b=", rb_cpBBSetB, 1);
  rb_define_method(c_cpBB, "r=", rb_cpBBSetR, 1);
  rb_define_method(c_cpBB, "t=", rb_cpBBSetT, 1);

  rb_define_method(c_cpBB, "intersect?", rb_cpBBintersects, 1);
  rb_define_method(c_cpBB, "intersects?", rb_cpBBintersects, 1);
  //containsBB
  //containsVect
  rb_define_method(c_cpBB, "contains?", rb_cpBBcontains, 1);
  rb_define_method(c_cpBB, "contain?", rb_cpBBcontains, 1);

  rb_define_method(c_cpBB, "contains_bb?", rb_cpBBcontainsBB, 1);
  rb_define_method(c_cpBB, "contain_bb?", rb_cpBBcontainsBB, 1);
  rb_define_method(c_cpBB, "contains_vect?", rb_cpBBcontainsVect, 1);
  rb_define_method(c_cpBB, "contain_vect?", rb_cpBBcontainsVect, 1);

  rb_define_method(c_cpBB, "clamp_vect", rb_cpBBClampVect, 1);
  rb_define_method(c_cpBB, "wrap_vect", rb_cpBBWrapVect, 1);
  rb_define_method(c_cpBB, "merge", rb_cpBBmerge, 1);
  rb_define_method(c_cpBB, "expand", rb_cpBBexpand, 1);


  rb_define_method(c_cpBB, "to_s", rb_cpBBToString, 0);
}
