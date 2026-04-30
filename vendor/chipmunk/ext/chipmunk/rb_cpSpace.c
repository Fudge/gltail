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

static ID id_call;
static ID id_begin;
static ID id_pre_solve;
static ID id_post_solve;
static ID id_separate;


VALUE c_cpSpace;


static VALUE
rb_cpSpaceAlloc(VALUE klass) {
  cpSpace *space = cpSpaceAlloc();
  return Data_Wrap_Struct(klass, NULL, cpSpaceFree, space);
}

static VALUE
rb_cpSpaceInitialize(VALUE self) {
  cpSpace *space = SPACE(self);
  cpSpaceInit(space);

  // These might as well be in one shared hash.
  rb_iv_set(self, "static_shapes", rb_ary_new());
  rb_iv_set(self, "active_shapes", rb_ary_new());
  rb_iv_set(self, "bodies", rb_ary_new());
  rb_iv_set(self, "constraints", rb_ary_new());
  rb_iv_set(self, "blocks", rb_hash_new());

  return self;
}

static VALUE
SPACEWRAP(cpSpace * space) {
  return Data_Wrap_Struct(c_cpSpace, NULL, cpSpaceFree, space);
}

static VALUE
rb_cpSpaceGetSleepTimeThreshold(VALUE self) {
  return INT2NUM(SPACE(self)->sleepTimeThreshold);
}

static VALUE
rb_cpSpaceSetSleepTimeThreshold(VALUE self, VALUE val) {
  SPACE(self)->sleepTimeThreshold = NUM2INT(val);
  return val;
}

static VALUE
rb_cpSpaceGetIdleSpeedThreshold(VALUE self) {
  return INT2NUM(SPACE(self)->idleSpeedThreshold);
}

static VALUE
rb_cpSpaceSetIdleSpeedThreshold(VALUE self, VALUE val) {
  SPACE(self)->idleSpeedThreshold = NUM2INT(val);
  return val;
}



static VALUE
rb_cpSpaceGetIterations(VALUE self) {
  return INT2NUM(SPACE(self)->iterations);
}

static VALUE
rb_cpSpaceSetIterations(VALUE self, VALUE val) {
  SPACE(self)->iterations = NUM2INT(val);
  return val;
}

static VALUE
rb_cpSpaceGetElasticIterations(VALUE self) {
  return INT2NUM(SPACE(self)->elasticIterations);
}

static VALUE
rb_cpSpaceSetElasticIterations(VALUE self, VALUE val) {
  SPACE(self)->elasticIterations = NUM2INT(val);
  return val;
}

static VALUE
rb_cpSpaceGetDamping(VALUE self) {
  return rb_float_new(SPACE(self)->damping);
}

static VALUE
rb_cpSpaceSetDamping(VALUE self, VALUE val) {
  SPACE(self)->damping = NUM2DBL(val);
  return val;
}

static VALUE
rb_cpSpaceGetGravity(VALUE self) {
  return VWRAP(self, &SPACE(self)->gravity);
}

static VALUE
rb_cpSpaceSetGravity(VALUE self, VALUE val) {
  SPACE(self)->gravity = *VGET(val);
  return val;
}

static int
doNothingCallback(cpArbiter *arb, cpSpace *space, void *data) {
  return 0;
}

// We need this as rb_obj_method_arity is not in 1.8.7
static int
cp_rb_obj_method_arity(VALUE self, ID id) {
  VALUE metho = rb_funcall(self, rb_intern("method"), 1, ID2SYM(id));
  VALUE arity = rb_funcall(metho, rb_intern("arity"), 0);
  return NUM2INT(arity);
}



// This callback function centralizes all collision callbacks.
// it also adds flexibility by changing theway the callback is called on the
// arity of the callback block or method. With arity0, no args are pased,
// with arity 1, the arbiter,
// with arity 2, body_a and body_b,
// with arity 3 or more -> body_a, body_b, arbiter
static int
do_callback(void * data, ID method, cpArbiter *arb) {
  int res      = 0;
  CP_ARBITER_GET_SHAPES(arb, a, b);
  VALUE object = (VALUE) data;
  VALUE va     = (VALUE)a->data;
  VALUE vb     = (VALUE)b->data;
  VALUE varb   = ARBWRAP(arb);
  int arity    = cp_rb_obj_method_arity(object, method);
  switch(arity) {
  case 0:
    return CP_BOOL_INT(rb_funcall(object, method, 0));
  case 1:
    return CP_BOOL_INT(rb_funcall(object, method, 1, varb));
  case 2:
    return CP_BOOL_INT(rb_funcall(object, method, 2, va, vb));
  case 3:
  default:
    return CP_BOOL_INT(rb_funcall(object, method, 3, va, vb, varb));
  }
  // we never get here
}


static int
compatibilityCallback(cpArbiter *arb, cpSpace *space, void *data) {
  return do_callback(data, id_call, arb);
}

static int
beginCallback(cpArbiter *arb, cpSpace *space, void *data) {
  return do_callback(data, id_begin, arb);
}

static int
preSolveCallback(cpArbiter *arb, cpSpace *space, void *data) {
  return do_callback(data, id_pre_solve, arb);
}

static void
postSolveCallback(cpArbiter *arb, cpSpace *space, void *data) {
  do_callback(data, id_post_solve, arb);
}

static void
separateCallback(cpArbiter *arb, cpSpace *space, void *data) {
  do_callback(data, id_separate, arb);
}


static int
respondsTo(VALUE obj, ID method) {
  VALUE value = rb_funcall(obj, rb_intern("respond_to?"), 1, ID2SYM(method));
  return RTEST(value);
}

static int
isBlock(VALUE obj) {
  return respondsTo(obj, id_call);
}

static VALUE
rb_cpSpaceAddCollisionHandler(int argc, VALUE *argv, VALUE self) {
  VALUE a, b, obj, block;
  obj = 0;
  rb_scan_args(argc, argv, "21&", &a, &b, &obj, &block);

  VALUE id_a   = rb_obj_id(a);
  VALUE id_b   = rb_obj_id(b);
  VALUE blocks = rb_iv_get(self, "blocks");

  if(RTEST(obj) && RTEST(block)) {
    rb_raise(rb_eArgError, "Cannot specify both a handler object and a block.");
  } else if(RTEST(block)) {
    cpSpaceAddCollisionHandler(
      SPACE(self), NUM2UINT(id_a), NUM2UINT(id_b),
      NULL,
      compatibilityCallback,
      NULL,
      NULL,
      (void *)block
      );

    rb_hash_aset(blocks, rb_ary_new3(2, id_a, id_b), block);
  } else if(RTEST(obj)) {
    cpSpaceAddCollisionHandler(
      SPACE(self), NUM2UINT(id_a), NUM2UINT(id_b),
      (respondsTo(obj, id_begin)      ? beginCallback     : NULL),
      (respondsTo(obj, id_pre_solve)  ? preSolveCallback  : NULL),
      (respondsTo(obj, id_post_solve) ? postSolveCallback : NULL),
      (respondsTo(obj, id_separate)   ? separateCallback  : NULL),
      (void *)obj
      );

    rb_hash_aset(blocks, rb_ary_new3(2, id_a, id_b), obj);
  } else {
    cpSpaceAddCollisionHandler(
      SPACE(self), NUM2UINT(id_a), NUM2UINT(id_b),
      NULL, doNothingCallback, NULL, NULL, NULL
      );
  }

  return Qnil;
}

static VALUE
rb_cpSpaceRemoveCollisionHandler(VALUE self, VALUE a, VALUE b) {
  VALUE id_a   = rb_obj_id(a);
  VALUE id_b   = rb_obj_id(b);
  cpSpaceRemoveCollisionHandler(SPACE(self), NUM2UINT(id_a), NUM2UINT(id_b));

  VALUE blocks = rb_iv_get(self, "blocks");
  rb_hash_delete(blocks, rb_ary_new3(2, id_a, id_b));

  return Qnil;
}

static VALUE
rb_cpSpaceSetDefaultCollisionHandler(int argc, VALUE *argv, VALUE self) {
  VALUE obj, block;
  rb_scan_args(argc, argv, "01&", &obj, &block);

  if(RTEST(obj) && RTEST(block)) {
    rb_raise(rb_eArgError, "Cannot specify both a handler object and a block.");
  } else if(RTEST(block)) {
    cpSpaceSetDefaultCollisionHandler(
      SPACE(self),
      NULL,
      compatibilityCallback,
      NULL,
      NULL,
      (void *)block
      );

    rb_hash_aset(rb_iv_get(self, "blocks"), ID2SYM(rb_intern("default")), block);
  } else if(RTEST(obj)) {
    cpSpaceSetDefaultCollisionHandler(
      SPACE(self),
      (respondsTo(obj, id_begin)      ? beginCallback     : NULL),
      (respondsTo(obj, id_pre_solve)  ? preSolveCallback  : NULL),
      (respondsTo(obj, id_post_solve) ? postSolveCallback : NULL),
      (respondsTo(obj, id_separate)   ? separateCallback  : NULL),
      (void *)obj
      );

    rb_hash_aset(rb_iv_get(self, "blocks"), ID2SYM(rb_intern("default")), obj);
  } else {
    cpSpaceSetDefaultCollisionHandler(
      SPACE(self), NULL, doNothingCallback, NULL, NULL, NULL
      );
  }

  return Qnil;
}

static void
poststepCallback(cpSpace *space, void *obj, void *data) {
  rb_funcall((VALUE)data, id_call, 2, SPACEWRAP(space), (VALUE)obj);
}


static VALUE
rb_cpSpaceAddPostStepCallback(int argc, VALUE *argv, VALUE self) {
  VALUE obj, block;
  rb_scan_args(argc, argv, "10&", &obj, &block);
  cpSpaceAddPostStepCallback(SPACE(self),
                             poststepCallback, (void *) obj, (void *) block);
  return self;
}

static VALUE
rb_cpSpaceAddShape(VALUE self, VALUE shape) {
  cpSpaceAddShape(SPACE(self), SHAPE(shape));
  rb_ary_push(rb_iv_get(self, "active_shapes"), shape);
  return shape;
}

static VALUE
rb_cpSpaceAddStaticShape(VALUE self, VALUE shape) {
  cpSpaceAddStaticShape(SPACE(self), SHAPE(shape));
  rb_ary_push(rb_iv_get(self, "static_shapes"), shape);
  return shape;
}

static VALUE
rb_cpSpaceAddBody(VALUE self, VALUE body) {
  cpSpaceAddBody(SPACE(self), BODY(body));
  rb_ary_push(rb_iv_get(self, "bodies"), body);
  return body;
}

static VALUE
rb_cpSpaceAddConstraint(VALUE self, VALUE constraint) {
  cpSpaceAddConstraint(SPACE(self), CONSTRAINT(constraint));
  rb_ary_push(rb_iv_get(self, "constraints"), constraint);
  return constraint;
}

static VALUE
rb_cpSpaceRemoveShape(VALUE self, VALUE shape) {
  VALUE ok = rb_ary_delete(rb_iv_get(self, "active_shapes"), shape);
  if(!(NIL_P(ok))) cpSpaceRemoveShape(SPACE(self), SHAPE(shape));
  return ok;
}

static VALUE
rb_cpSpaceRemoveStaticShape(VALUE self, VALUE shape) {
  VALUE ok = rb_ary_delete(rb_iv_get(self, "static_shapes"), shape);
  if(!(NIL_P(ok))) cpSpaceRemoveStaticShape(SPACE(self), SHAPE(shape));
  return ok;
}

static VALUE
rb_cpSpaceRemoveBody(VALUE self, VALUE body) {
  VALUE ok = rb_ary_delete(rb_iv_get(self, "bodies"), body);
  if(!(NIL_P(ok))) cpSpaceRemoveBody(SPACE(self), BODY(body));
  return ok;
}

static VALUE
rb_cpSpaceRemoveConstraint(VALUE self, VALUE constraint) {
  VALUE ok = rb_ary_delete(rb_iv_get(self, "constraints"), constraint);
  if(!(NIL_P(ok))) cpSpaceRemoveConstraint(SPACE(self), CONSTRAINT(constraint));
  return ok;
}

static VALUE
rb_cpSpaceResizeStaticHash(VALUE self, VALUE dim, VALUE count) {
  cpSpaceResizeStaticHash(SPACE(self), NUM2DBL(dim), NUM2INT(count));
  return Qnil;
}

static VALUE
rb_cpSpaceResizeActiveHash(VALUE self, VALUE dim, VALUE count) {
  cpSpaceResizeActiveHash(SPACE(self), NUM2DBL(dim), NUM2INT(count));
  return Qnil;
}

static VALUE
rb_cpSpaceRehashStatic(VALUE self) {
  cpSpaceRehashStatic(SPACE(self));
  return Qnil;
}

static VALUE
rb_cpSpaceRehashShape(VALUE self, VALUE shape) {
  cpSpaceRehashShape(SPACE(self), SHAPE(shape));
  return Qnil;
}


static unsigned int
get_layers(VALUE layers) {
  if (NIL_P(layers)) return ~0;
  return NUM2UINT(layers);
}

static unsigned int
get_group(VALUE group) {
  if (NIL_P(group)) return 0;
  return NUM2UINT(group);
}

static void
pointQueryCallback(cpShape *shape, VALUE block) {
  rb_funcall(block, id_call, 1, (VALUE)shape->data);
}

static VALUE
rb_cpSpacePointQuery(int argc, VALUE *argv, VALUE self) {
  VALUE point, layers, group, block;
  rb_scan_args(argc, argv, "12&", &point, &layers, &group, &block);

  cpSpacePointQuery(
    SPACE(self), *VGET(point), get_layers(layers), get_group(group),
    (cpSpacePointQueryFunc)pointQueryCallback, (void *)block
    );

  return Qnil;
}

static VALUE
rb_cpSpacePointQueryFirst(int argc, VALUE *argv, VALUE self) {
  VALUE point, layers, group;
  rb_scan_args(argc, argv, "12", &point, &layers, &group);

  cpShape *shape = cpSpacePointQueryFirst(
    SPACE(self), *VGET(point),
    get_layers(layers), get_group(group)
    );

  return (shape ? (VALUE)shape->data : Qnil);
}

static void
segmentQueryCallback(cpShape *shape, cpFloat t, cpVect n, VALUE block) {
  rb_funcall(block, id_call, 3, (VALUE)shape->data, rb_float_new(t), VNEW(n));
}

static VALUE
rb_cpSpaceSegmentQuery(int argc, VALUE *argv, VALUE self) {
  VALUE a, b, layers, group, block;
  rb_scan_args(argc, argv, "22&", &a, &b, &layers, &group, &block);

  cpSpaceSegmentQuery(
    SPACE(self), *VGET(a), *VGET(b),
    get_layers(layers), get_group(group),
    (cpSpaceSegmentQueryFunc)segmentQueryCallback, (void *)block
    );

  return Qnil;
}

static VALUE
rb_cpSpaceSegmentQueryFirst(int argc, VALUE *argv, VALUE self) {
  VALUE a, b, layers, group, block;
  cpSegmentQueryInfo info = { NULL, 1.0f, cpvzero};

  rb_scan_args(argc, argv, "22&", &a, &b, &layers, &group, &block);

  cpSpaceSegmentQueryFirst(SPACE(self), *VGET(a), *VGET(b),
                           get_layers(layers), get_group(group), &info);
  // contrary to the standard chipmunk bindings, we also return a
  // struct here with then needed values.
  if(info.shape) {
    return rb_cpSegmentQueryInfoNew((VALUE)info.shape->data, rb_float_new(info.t), VNEW(info.n));
  }
  return Qnil;

}


static void
bbQueryCallback(cpShape *shape, VALUE block) {
  rb_funcall(block, id_call, 1, (VALUE)shape->data);
}

/* Bounding box query. */
static VALUE
rb_cpSpaceBBQuery(int argc, VALUE *argv, VALUE self) {
  VALUE bb, layers, group, block;
  unsigned int l = ~0;
  unsigned int g =  0;
  rb_scan_args(argc, argv, "12&", &bb, &layers, &group, &block);

  if (!NIL_P(layers)) l = NUM2UINT(layers);
  if (!NIL_P(group)) g = NUM2UINT(group);

  cpSpaceBBQuery(
    SPACE(self), *BBGET(bb), l, g,
    (cpSpaceBBQueryFunc)bbQueryCallback, (void *)block
    );

  return Qnil;
}

static void
shapeQueryCallback(cpShape *shape, cpContactPointSet *points, VALUE block) {
  rb_funcall(block, id_call, 1, (VALUE)shape->data);
}

/* Shape query. */
static VALUE
rb_cpSpaceShapeQuery(int argc, VALUE *argv, VALUE self) {
  VALUE shape, block;
  rb_scan_args(argc, argv, "1&", &shape, &block);

  cpSpaceShapeQuery(
    SPACE(self), SHAPE(shape),
    (cpSpaceShapeQueryFunc)shapeQueryCallback, (void *)block
    );

  return Qnil;
}

static VALUE
rb_cpSpaceStep(VALUE self, VALUE dt) {
  cpSpaceStep(SPACE(self), NUM2DBL(dt));
  return Qnil;
}

static VALUE
rb_cpSpaceGetData(VALUE self) {
  return rb_iv_get(self, "data");
}

static VALUE
rb_cpSpaceSetData(VALUE self, VALUE val) {
  rb_iv_set(self, "data", val);
  return val;
}


static VALUE
rb_cpSpaceActivateShapesTouchingShape(VALUE self, VALUE shape) {
  cpSpaceActivateShapesTouchingShape(SPACE(self), SHAPE(shape));
  return self;
}


/** in chipmunk 6
   static VALUE
   rb_cpSpaceUseSpatialHash(VALUE self, VALUE dim, VALUE count) {
   cpSpaceUseSpatialHash(SPACE(self), NUM2DBL(dim), NUM2INT(count));
   return Qnil;
   }
 */



void
Init_cpSpace(void) {
  id_call       = rb_intern("call");
  id_begin      = rb_intern("begin");
  id_pre_solve  = rb_intern("pre_solve");
  id_post_solve = rb_intern("post_solve");
  id_separate   = rb_intern("separate");

  c_cpSpace     = rb_define_class_under(m_Chipmunk, "Space", rb_cObject);
  rb_define_alloc_func(c_cpSpace, rb_cpSpaceAlloc);
  rb_define_method(c_cpSpace, "initialize", rb_cpSpaceInitialize, 0);

  rb_define_method(c_cpSpace, "iterations", rb_cpSpaceGetIterations, 0);
  rb_define_method(c_cpSpace, "iterations=", rb_cpSpaceSetIterations, 1);

  rb_define_method(c_cpSpace, "elastic_iterations", rb_cpSpaceGetElasticIterations, 0);
  rb_define_method(c_cpSpace, "elastic_iterations=", rb_cpSpaceSetElasticIterations, 1);

  rb_define_method(c_cpSpace, "damping", rb_cpSpaceGetDamping, 0);
  rb_define_method(c_cpSpace, "damping=", rb_cpSpaceSetDamping, 1);

  rb_define_method(c_cpSpace, "gravity", rb_cpSpaceGetGravity, 0);
  rb_define_method(c_cpSpace, "gravity=", rb_cpSpaceSetGravity, 1);

  rb_define_method(c_cpSpace, "add_collision_func",
                   rb_cpSpaceAddCollisionHandler, -1);

  rb_define_method(c_cpSpace, "add_collision_handler",
                   rb_cpSpaceAddCollisionHandler, -1);

  rb_define_method(c_cpSpace, "on_collision",
                   rb_cpSpaceAddCollisionHandler, -1);

  rb_define_method(c_cpSpace, "remove_collision_func",
                   rb_cpSpaceRemoveCollisionHandler, 2);

  rb_define_method(c_cpSpace, "remove_collision_handler",
                   rb_cpSpaceRemoveCollisionHandler, 2);
  rb_define_method(c_cpSpace, "remove_collision",
                   rb_cpSpaceRemoveCollisionHandler, 2);

  rb_define_method(c_cpSpace, "set_default_collision_func",
                   rb_cpSpaceSetDefaultCollisionHandler, -1);
  rb_define_method(c_cpSpace, "set_default_collision_handler",
                   rb_cpSpaceSetDefaultCollisionHandler, -1);
  rb_define_method(c_cpSpace, "on_default_collision",
                   rb_cpSpaceSetDefaultCollisionHandler, -1);

  rb_define_method(c_cpSpace, "add_post_step_callback",
                   rb_cpSpaceAddPostStepCallback, -1);
  rb_define_method(c_cpSpace, "on_post_step",
                   rb_cpSpaceAddPostStepCallback, -1);




  rb_define_method(c_cpSpace, "add_shape", rb_cpSpaceAddShape, 1);
  rb_define_method(c_cpSpace, "add_static_shape", rb_cpSpaceAddStaticShape, 1);
  rb_define_method(c_cpSpace, "add_body", rb_cpSpaceAddBody, 1);
  rb_define_method(c_cpSpace, "add_constraint", rb_cpSpaceAddConstraint, 1);

  rb_define_method(c_cpSpace, "remove_shape", rb_cpSpaceRemoveShape, 1);
  rb_define_method(c_cpSpace, "remove_static_shape", rb_cpSpaceRemoveStaticShape, 1);
  rb_define_method(c_cpSpace, "remove_body", rb_cpSpaceRemoveBody, 1);
  rb_define_method(c_cpSpace, "remove_constraint", rb_cpSpaceRemoveConstraint, 1);

  rb_define_method(c_cpSpace, "resize_static_hash", rb_cpSpaceResizeStaticHash, 2);
  rb_define_method(c_cpSpace, "resize_active_hash", rb_cpSpaceResizeActiveHash, 2);
  rb_define_method(c_cpSpace, "rehash_static", rb_cpSpaceRehashStatic, 0);
  rb_define_method(c_cpSpace, "rehash_shape", rb_cpSpaceRehashShape, 1);

  rb_define_method(c_cpSpace, "point_query", rb_cpSpacePointQuery, -1);
  rb_define_method(c_cpSpace, "point_query_first", rb_cpSpacePointQueryFirst, -1);
  rb_define_method(c_cpSpace, "shape_point_query", rb_cpSpacePointQueryFirst, -1);


  rb_define_method(c_cpSpace, "segment_query", rb_cpSpaceSegmentQuery, -1);
  rb_define_method(c_cpSpace, "segment_query_first", rb_cpSpaceSegmentQueryFirst, -1);

  rb_define_method(c_cpSpace, "bb_query", rb_cpSpaceBBQuery, -1);
  rb_define_method(c_cpSpace, "shape_query", rb_cpSpaceShapeQuery, -1);


  rb_define_method(c_cpSpace, "step", rb_cpSpaceStep, 1);

  rb_define_method(c_cpSpace, "object", rb_cpSpaceGetData, 0);
  rb_define_method(c_cpSpace, "object=", rb_cpSpaceSetData, 1);

  rb_define_method(c_cpSpace, "sleep_time_threshold=",
                   rb_cpSpaceSetSleepTimeThreshold, 1);
  rb_define_method(c_cpSpace, "sleep_time_threshold",
                   rb_cpSpaceGetSleepTimeThreshold, 0);
  rb_define_method(c_cpSpace, "idle_speed_threshold=",
                   rb_cpSpaceSetIdleSpeedThreshold, 1);
  rb_define_method(c_cpSpace, "idle_speed_threshold",
                   rb_cpSpaceGetIdleSpeedThreshold, 0);

  // also define slghtly less verbose API
  rb_define_method(c_cpSpace, "sleep_time=",
                   rb_cpSpaceSetSleepTimeThreshold, 1);
  rb_define_method(c_cpSpace, "sleep_time",
                   rb_cpSpaceGetSleepTimeThreshold, 0);
  rb_define_method(c_cpSpace, "idle_speed=",
                   rb_cpSpaceSetIdleSpeedThreshold, 1);
  rb_define_method(c_cpSpace, "idle_speed",
                   rb_cpSpaceGetIdleSpeedThreshold, 0);

  rb_define_method(c_cpSpace, "activate_shapes_touching_shape",
                   rb_cpSpaceActivateShapesTouchingShape, 1);

  // this is nicer, though :)
  rb_define_method(c_cpSpace, "activate_touching",
                   rb_cpSpaceActivateShapesTouchingShape, 1);



}
