/* Copyright (c) 2010 Beoran (beoran@rubyforge.org)
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

VALUE c_cpArbiter;

/*
 * I quote the C docs on cpArbiter:
 * Memory Management
 * You should never need to create an arbiter, nor will you ever need to free
 * one as they are handled by the space. More importantly, because they are
 * handled by the space you should never hold onto a reference to an arbiter as
 * you don't know when they will be destroyed. Use them within the callback
 * where they are given to you and then forget about them or copy out the
 * information you need from them.
 *
 * This means that Arbiter doesn't need an initialize, and also
 * does NOT need any garbage collection.
 */

VALUE
ARBWRAP(cpArbiter *arb) {
  return Data_Wrap_Struct(c_cpArbiter, NULL, NULL, arb);
}


/*
   static VALUE
   rb_cpArbiterAlloc(VALUE klass)
   {
   cpArbiter *arb = cpArbiterAlloc();
   return Data_Wrap_Struct(klass, NULL, cpArbiterFree, arb);
   }


   static VALUE
   rb_cpArbiterInitialize(VALUE self, VALUE a, VALUE b, VALUE r, VALUE t)
   {
   cpArbiter *arb = ARBITER(self);
   cpShape   *sa  = SHAPE(a);
   cpShape   *sb  = SHAPE(b);
   cpArbiterInit(arb, sa, sb);
   return self;
   }
 */

static VALUE
rb_cpArbiterTotalImpulse(VALUE self) {
  cpArbiter *arb = ARBITER(self);
  return VNEW(cpArbiterTotalImpulse(arb));
}

static VALUE
rb_cpArbiterTotalImpulseWithFriction(VALUE self) {
  cpArbiter *arb = ARBITER(self);
  return VNEW(cpArbiterTotalImpulseWithFriction(arb));
}

static VALUE
rb_cpArbiterGetImpulse(int argc, VALUE *argv, VALUE self) {
  VALUE friction = Qnil;
  rb_scan_args(argc, argv, "01", &friction);
  if (NIL_P(friction) || friction == Qnil) {
    return rb_cpArbiterTotalImpulse(self);
  }
  /* Here, it's with friction */
  return rb_cpArbiterTotalImpulseWithFriction(self);
}


static VALUE
rb_cpArbiterIgnore(VALUE self) {
  cpArbiter *arb = ARBITER(self);
  cpArbiterIgnore(arb);
  return Qnil;
}

static VALUE
rb_cpArbiterGetShapes(VALUE self) {
  cpArbiter *arb = ARBITER(self);
  CP_ARBITER_GET_SHAPES(arb, a, b)
  return rb_ary_new3(2, (VALUE)a->data, (VALUE)b->data);
}

static VALUE
rb_cpArbiterGetBodies(VALUE self) {
  cpArbiter *arb = ARBITER(self);
  CP_ARBITER_GET_BODIES(arb, a, b)
  return rb_ary_new3(2, (VALUE)a->data, (VALUE)b->data);
}


static VALUE
rb_cpArbiterGetA(VALUE self) {
  cpArbiter *arb = ARBITER(self);
  CP_ARBITER_GET_SHAPES(arb, a, b)
  return (VALUE)a->data;
}

static VALUE
rb_cpArbiterGetB(VALUE self) {
  cpArbiter *arb = ARBITER(self);
  CP_ARBITER_GET_SHAPES(arb, a, b)
  return (VALUE)b->data;
}

static VALUE
rb_cpArbiterGetE(VALUE self) {
  return rb_float_new(ARBITER(self)->e);
}

static VALUE
rb_cpArbiterSetE(VALUE self, VALUE e) {
  ARBITER(self)->e = NUM2DBL(e);
  return e;
}

static VALUE
rb_cpArbiterGetCount(VALUE self) {
  return INT2NUM(cpArbiterGetCount(ARBITER(self)));
}

static VALUE
rb_cpArbiterGetU(VALUE self) {
  return rb_float_new(ARBITER(self)->u);
}

static VALUE
rb_cpArbiterSetU(VALUE self, VALUE u) {
  ARBITER(self)->u = NUM2DBL(u);
  return u;
}

static VALUE
rb_cpArbiterIsFirstContact(VALUE self) {
  int b = cpArbiterIsFirstContact(ARBITER(self));
  return b ? Qtrue : Qfalse;
}

static int
arbiterBadIndex(cpArbiter *arb, int i) {
  return ((i < 0) || (i >= cpArbiterGetCount(arb)));
}


static VALUE
rb_cpArbiterGetNormal(VALUE self, VALUE index) {
  cpArbiter *arb = ARBITER(self);
  int i          = NUM2INT(index);
  if (arbiterBadIndex(arb, i)) {
    rb_raise(rb_eIndexError, "No such normal.");
  }
  return VNEW(cpArbiterGetNormal(arb, i));
}

static VALUE
rb_cpArbiterGetPoint(VALUE self, VALUE index) {
  cpArbiter *arb = ARBITER(self);
  int i          = NUM2INT(index);
  if (arbiterBadIndex(arb, i)) {
    rb_raise(rb_eIndexError, "No such contact point.");
  }
  return VNEW(cpArbiterGetPoint(arb, i));
}

static VALUE
rb_cpArbiterGetDepth(VALUE self, VALUE index) {
  cpArbiter *arb = ARBITER(self);
  int i          = NUM2INT(index);
  if (arbiterBadIndex(arb, i)) {
    rb_raise(rb_eIndexError, "No such depth.");
  }
  // there"s a typo in the cpArbiter.h class.
  return rb_float_new(cpArbiteGetDepth(arb, i));
}


static VALUE
rb_cpArbiterToString(VALUE self) {
  char str[256];
  cpArbiter *arb = ARBITER(self);
  sprintf(str, "#<CP::Arbiter:%p>", arb);
  return rb_str_new2(str);
}

static VALUE
rb_cpArbiterEachContact(VALUE self) {
  cpArbiter *arb = ARBITER(self);
  int i          = 0;
  for( i = 0; i < cpArbiterGetCount(arb); i++) {
    VALUE index = INT2NUM(i);
    VALUE contact, normal;
    normal  = rb_cpArbiterGetNormal(self, index);
    contact = rb_cpArbiterGetPoint(self, index);
    /* Yield an array of contact and normal */
    rb_yield(rb_ary_new3(2, contact, normal));
  }
  return self;
}

VALUE c_cpContactPoint;

// Helper that allocates and initializes a ContactPoint struct.
VALUE
rb_cpContactPointNew(VALUE point, VALUE normal, VALUE dist) {
  return rb_struct_new(c_cpContactPoint, point, normal, dist);
}

VALUE
rb_cpArbiterGetContactPointSet(VALUE arbiter) {
  cpArbiter * arb       = ARBITER(arbiter);
  cpContactPointSet set = cpArbiterGetContactPointSet(arb);
  VALUE result          = rb_ary_new();
  for(int index = 0; index < set.count; index++) {
    VALUE point   = VNEW(set.points[index].point);
    VALUE normal  = VNEW(set.points[index].normal);
    VALUE dist    = DBL2NUM(set.points[index].dist);
    VALUE contact = rb_cpContactPointNew(point, normal, dist);
    rb_ary_push(result, contact);
  }
  return result;
}



void
Init_cpArbiter(void) {
  c_cpArbiter = rb_define_class_under(m_Chipmunk, "Arbiter", rb_cObject);
  /*
     rb_define_alloc_func(c_cpArbiter, rb_cpArbiterAlloc);
     rb_define_method(c_cpArbiter    , "initialize", rb_cpArbiterInitialize, 2);
   */
  rb_define_method(c_cpArbiter, "a", rb_cpArbiterGetA, 0);
  rb_define_method(c_cpArbiter, "b", rb_cpArbiterGetB, 0);
  rb_define_method(c_cpArbiter, "e", rb_cpArbiterGetE, 0);
  rb_define_method(c_cpArbiter, "u", rb_cpArbiterGetU, 0);
  rb_define_method(c_cpArbiter, "e=", rb_cpArbiterSetE, 1);
  rb_define_method(c_cpArbiter, "u=", rb_cpArbiterSetU, 1);

  rb_define_method(c_cpArbiter, "point", rb_cpArbiterGetPoint, 1);
  rb_define_method(c_cpArbiter, "normal", rb_cpArbiterGetNormal, 1);
  rb_define_method(c_cpArbiter, "depth" , rb_cpArbiterGetDepth, 1);
  rb_define_method(c_cpArbiter, "impulse", rb_cpArbiterGetImpulse, -1);

  rb_define_method(c_cpArbiter, "to_s", rb_cpArbiterToString, 0);

  rb_define_method(c_cpArbiter, "first_contact?", rb_cpArbiterIsFirstContact, 0);
  rb_define_method(c_cpArbiter, "count", rb_cpArbiterGetCount, 0);
  rb_define_method(c_cpArbiter, "contacts", rb_cpArbiterGetCount, 0);
  rb_define_method(c_cpArbiter, "size", rb_cpArbiterGetCount, 0);
  rb_define_method(c_cpArbiter, "length", rb_cpArbiterGetCount, 0);
  rb_define_method(c_cpArbiter, "each_contact", rb_cpArbiterEachContact, 0);

  rb_define_method(c_cpArbiter, "shapes", rb_cpArbiterGetShapes, 0);
  rb_define_method(c_cpArbiter, "bodies", rb_cpArbiterGetBodies, 0);
  /* Ignore is new in the 5.x API, I think. */
  rb_define_method(c_cpArbiter, "ignore", rb_cpArbiterIgnore, 0);
  rb_define_method(c_cpArbiter, "points", rb_cpArbiterGetContactPointSet, 0);


  /* Use a struct for this small class. More efficient. */
  c_cpContactPoint = rb_struct_define("ContactPoint",
                                      "point", "normal", "dist", NULL);
  rb_define_const(m_Chipmunk, "ContactPoint", c_cpContactPoint);


}
