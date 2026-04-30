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

VALUE c_cpBody;
VALUE c_cpStaticBody;

static VALUE
rb_cpBodyAlloc(VALUE klass) {
  cpBody *body = cpBodyNew(1.0f, 1.0f);
  return Data_Wrap_Struct(klass, NULL, cpBodyFree, body);
}

static VALUE
rb_cpBodyInitialize(VALUE self, VALUE m, VALUE i) {
  cpBody *body = BODY(self);
  cpBodyInit(body, NUM2DBL(m), NUM2DBL(i));
  body->data = (void *)self;
  return self;
}

static VALUE
rb_cpBodyAllocStatic(VALUE klass) {
  cpBody *body = cpBodyNewStatic();
  return Data_Wrap_Struct(c_cpStaticBody, NULL, cpBodyFree, body);
}

static VALUE
rb_cpBodyInitializeStatic(VALUE self) {
  cpBody *body = STATICBODY(self);
  cpBodyInitStatic(body);
  body->data = (void *)self;
  return self;
}

static VALUE
rb_cpStaticBodyNew(VALUE klass) {
  return rb_cpBodyInitializeStatic(rb_cpBodyAllocStatic(klass));
}


static VALUE
rb_cpBodyGetMass(VALUE self) {
  return rb_float_new(BODY(self)->m);
}

static VALUE
rb_cpBodyGetMassInv(VALUE self) {
  return rb_float_new(BODY(self)->m_inv);
}

static VALUE
rb_cpBodyGetMoment(VALUE self) {
  return rb_float_new(BODY(self)->i);
}


static VALUE
rb_cpBodyGetMomentInv(VALUE self) {
  return rb_float_new(BODY(self)->i_inv);
}

static VALUE
rb_cpBodyGetPos(VALUE self) {
  return VWRAP(self, &BODY(self)->p);
}

static VALUE
rb_cpBodyGetVel(VALUE self) {
  return VWRAP(self, &BODY(self)->v);
}

static VALUE
rb_cpBodyGetForce(VALUE self) {
  return VWRAP(self, &BODY(self)->f);
}

static VALUE
rb_cpBodyGetAngle(VALUE self) {
  return rb_float_new(BODY(self)->a);
}

static VALUE
rb_cpBodyGetAVel(VALUE self) {
  return rb_float_new(BODY(self)->w);
}

static VALUE
rb_cpBodyGetTorque(VALUE self) {
  return rb_float_new(BODY(self)->t);
}

static VALUE
rb_cpBodyGetVLimit(VALUE self) {
  return rb_float_new(BODY(self)->v_limit);
}

static VALUE
rb_cpBodyGetWLimit(VALUE self) {
  return rb_float_new(BODY(self)->w_limit);
}


static VALUE
rb_cpBodyGetRot(VALUE self) {
  return VWRAP(self, &BODY(self)->rot);
}


static VALUE
rb_cpBodySetMass(VALUE self, VALUE val) {
  cpBodySetMass(BODY(self), NUM2DBL(val));
  return val;
}

static VALUE
rb_cpBodySetMoment(VALUE self, VALUE val) {
  cpBodySetMoment(BODY(self), NUM2DBL(val));
  return val;
}

static VALUE
rb_cpBodySetPos(VALUE self, VALUE val) {
  BODY(self)->p = *VGET(val);
  return val;
}

static VALUE
rb_cpBodySetVel(VALUE self, VALUE val) {
  BODY(self)->v = *VGET(val);
  return val;
}

static VALUE
rb_cpBodySetForce(VALUE self, VALUE val) {
  BODY(self)->f = *VGET(val);
  return val;
}

static VALUE
rb_cpBodySetAngle(VALUE self, VALUE val) {
  cpBodySetAngle(BODY(self), NUM2DBL(val));
  return val;
}

static VALUE
rb_cpBodySetAVel(VALUE self, VALUE val) {
  BODY(self)->w = NUM2DBL(val);
  return val;
}

static VALUE
rb_cpBodySetTorque(VALUE self, VALUE val) {
  BODY(self)->t = NUM2DBL(val);
  return val;
}


static VALUE
rb_cpBodySetVLimit(VALUE self, VALUE val) {
  BODY(self)->v_limit = NUM2DBL(val);
  return val;
}

static VALUE
rb_cpBodySetWLimit(VALUE self, VALUE val) {
  BODY(self)->w_limit = NUM2DBL(val);
  return val;
}



static VALUE
rb_cpBodyLocal2World(VALUE self, VALUE v) {
  return VNEW(cpBodyLocal2World(BODY(self), *VGET(v)));
}

static VALUE
rb_cpBodyWorld2Local(VALUE self, VALUE v) {
  return VNEW(cpBodyWorld2Local(BODY(self), *VGET(v)));
}

static VALUE
rb_cpBodyResetForces(VALUE self) {
  cpBodyResetForces(BODY(self));
  return self;
}

static VALUE
rb_cpBodyApplyForce(VALUE self, VALUE f, VALUE r) {
  cpBodyApplyForce(BODY(self), *VGET(f), *VGET(r));
  return self;
}

static VALUE
rb_cpBodyApplyImpulse(VALUE self, VALUE j, VALUE r) {
  cpBodyApplyImpulse(BODY(self), *VGET(j), *VGET(r));
  return self;
}

static VALUE
rb_cpBodyUpdateVelocity(VALUE self, VALUE g, VALUE dmp, VALUE dt) {
  cpBodyUpdateVelocity(BODY(self), *VGET(g), NUM2DBL(dmp), NUM2DBL(dt));
  return self;
}

static VALUE
rb_cpBodyUpdatePosition(VALUE self, VALUE dt) {
  cpBodyUpdatePosition(BODY(self), NUM2DBL(dt));
  return self;
}

static VALUE
rb_cpBodyActivate(VALUE self) {
  cpBodyActivate(BODY(self));
  return self;
}

static cpBody *
rb_cpBodySleepValidate(VALUE vbody) {
  cpBody * body  = BODY(vbody);
  cpSpace *space = body->space;
  if(!space) {
    rb_raise(rb_eArgError, "Cannot put a body to sleep that has not been added to a space.");
    return NULL;
  }
  if (cpBodyIsStatic(body) && cpBodyIsRogue(body)) {
    rb_raise(rb_eArgError, "Rogue AND static bodies cannot be put to sleep.");
    return NULL;
  }
  if(space->locked) {
    rb_raise(rb_eArgError, "Bodies can not be put to sleep during a query or a call to Space#add_collision_func. Put these calls into a post-step callback using Space#add_collision_handler.");
    return NULL;
  }
  return body;
}

static VALUE
rb_cpBodySleep(VALUE self) {
  cpBody * body = rb_cpBodySleepValidate(self);
  cpBodySleep(body);
  return self;
}

static VALUE
rb_cpBodySleepWithGroup(VALUE self, VALUE vgroup) {
  cpBody * group = NIL_P(vgroup) ? NULL : rb_cpBodySleepValidate(vgroup);
  cpBody * body  = rb_cpBodySleepValidate(self);

  if (!cpBodyIsSleeping(group)) {
    rb_raise(rb_eArgError, "Cannot use a non-sleeping body as a group identifier.");
  }
  cpBodySleepWithGroup(body, group);
  return self;
}


static VALUE
rb_cpBodyIsSleeping(VALUE self) {
  return cpBodyIsSleeping(BODY(self)) ? Qtrue : Qfalse;
}

static VALUE
rb_cpBodyIsStatic(VALUE self) {
  cpBody * body = BODY(self);
  cpBool stat   = 0;
  // cpBodyInitStatic(body);
  stat = cpBodyIsStatic(body);
  return stat ? Qtrue : Qfalse;
  //
}

static VALUE
rb_cpBodyIsRogue(VALUE self) {
  return cpBodyIsRogue(BODY(self)) ? Qtrue : Qfalse;
}

ID id_velocity_func;
ID id_speed_func;

static int
respondsTo(VALUE obj, ID method) {
  VALUE value = rb_funcall(obj, rb_intern("respond_to?"), 1, ID2SYM(method));
  return RTEST(value);
}

/*

   typedef void (*cpBodyVelocityFunc)(struct cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt);
   typedef void (*cpBodyPositionFunc)(struct cpBody *body, cpFloat dt);
 */

static void
bodyVelocityCallback(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt) {
  VALUE vbody    = (VALUE)(body->data);
  VALUE block    = rb_iv_get(vbody, "velocity_func");
  VALUE vgravity = VNEW(gravity);
  VALUE vdamping = rb_float_new(damping);
  VALUE vdt      = rb_float_new(dt);
  rb_funcall(block, rb_intern("call"), 4, vbody, vgravity, vdamping, vdt);
}

static VALUE
rb_cpBodySetVelocityFunc(int argc, VALUE *argv, VALUE self) {
  VALUE block;
  cpBody * body = BODY(self);
  rb_scan_args(argc, argv, "&", &block);
  // Restore defaults if no block
  if (NIL_P(block)) {
    body->velocity_func = cpBodyUpdateVelocity; //Default;
    return Qnil;
  }
  // set block for use in callback
  rb_iv_set(self, "velocity_func", block);
  body->velocity_func = bodyVelocityCallback;
  return self;
}

static void
bodyPositionCallback(cpBody *body, cpFloat dt) {
  VALUE vbody = (VALUE)(body->data);
  VALUE block = rb_iv_get(vbody, "position_func");
  VALUE vdt   = rb_float_new(dt);
  rb_funcall(block, rb_intern("call"), 2, vbody, vdt);
}

static VALUE
rb_cpBodySetPositionFunc(int argc, VALUE *argv, VALUE self) {
  VALUE block;
  cpBody * body = BODY(self);
  rb_scan_args(argc, argv, "&", &block);
  // Restore defaults if no block
  if (NIL_P(block)) {
    body->position_func = cpBodyUpdatePosition; //Default;
    return Qnil;
  }
  // set block for use in callback
  rb_iv_set(self, "position_func", block);
  body->position_func = bodyPositionCallback;
  return self;
}

static VALUE
rb_cpBodyGetData(VALUE self) {
  return rb_iv_get(self, "data");
}

static VALUE
rb_cpBodySetData(VALUE self, VALUE val) {
  rb_iv_set(self, "data", val);
  return val;
}


static VALUE
rb_cpBodySlew(VALUE self, VALUE pos, VALUE dt) {
  cpBodySlew(BODY(self), *VGET(pos), NUM2DBL(dt));
  return self;
}

static VALUE
rb_cpBodyKineticEnergy(VALUE self) {
  return DBL2NUM(cpBodyKineticEnergy(BODY(self)));
}


void
Init_cpBody(void) {
  c_cpBody       = rb_define_class_under(m_Chipmunk, "Body", rb_cObject);
  rb_define_alloc_func(c_cpBody, rb_cpBodyAlloc);
  rb_define_method(c_cpBody, "initialize", rb_cpBodyInitialize, 2);

  c_cpStaticBody = rb_define_class_under(m_Chipmunk, "StaticBody", c_cpBody);
  rb_define_alloc_func(c_cpStaticBody, rb_cpBodyAlloc);
  // rb_define_alloc_func will not work here, since superclass defines this.
  // so, we define new here in stead.
  // rb_define_singleton_method(c_cpStaticBody, "new", rb_cpStaticBodyNew, 0);
  rb_define_method(c_cpStaticBody, "initialize", rb_cpBodyInitializeStatic, 0);
  rb_define_singleton_method(c_cpBody, "new_static",  rb_cpStaticBodyNew, 0);

  rb_define_method(c_cpBody, "m", rb_cpBodyGetMass, 0);
  rb_define_method(c_cpBody, "i", rb_cpBodyGetMoment, 0);

  rb_define_method(c_cpBody, "p", rb_cpBodyGetPos, 0);
  rb_define_method(c_cpBody, "v", rb_cpBodyGetVel, 0);
  rb_define_method(c_cpBody, "f", rb_cpBodyGetForce, 0);
  rb_define_method(c_cpBody, "a", rb_cpBodyGetAngle, 0);
  rb_define_method(c_cpBody, "w", rb_cpBodyGetAVel, 0);
  rb_define_method(c_cpBody, "t", rb_cpBodyGetTorque, 0);
  rb_define_method(c_cpBody, "rot", rb_cpBodyGetRot, 0);

  rb_define_method(c_cpBody, "m=", rb_cpBodySetMass, 1);
  rb_define_method(c_cpBody, "i=", rb_cpBodySetMoment, 1);
  rb_define_method(c_cpBody, "p=", rb_cpBodySetPos, 1);
  rb_define_method(c_cpBody, "v=", rb_cpBodySetVel, 1);
  rb_define_method(c_cpBody, "f=", rb_cpBodySetForce, 1);
  rb_define_method(c_cpBody, "a=", rb_cpBodySetAngle, 1);
  rb_define_method(c_cpBody, "w=", rb_cpBodySetAVel, 1);
  rb_define_method(c_cpBody, "t=", rb_cpBodySetTorque, 1);

  rb_define_method(c_cpBody, "mass", rb_cpBodyGetMass, 0);
  rb_define_method(c_cpBody, "moment", rb_cpBodyGetMoment, 0);
  rb_define_method(c_cpBody, "pos", rb_cpBodyGetPos, 0);
  rb_define_method(c_cpBody, "vel", rb_cpBodyGetVel, 0);
  rb_define_method(c_cpBody, "force", rb_cpBodyGetForce, 0);
  rb_define_method(c_cpBody, "angle", rb_cpBodyGetAngle, 0);
  rb_define_method(c_cpBody, "ang_vel", rb_cpBodyGetAVel, 0);
  rb_define_method(c_cpBody, "torque", rb_cpBodyGetTorque, 0);
  rb_define_method(c_cpBody, "rot", rb_cpBodyGetRot, 0);

  rb_define_method(c_cpBody, "m_inv", rb_cpBodyGetMassInv, 0);
  rb_define_method(c_cpBody, "mass_inv", rb_cpBodyGetMassInv, 0);
  rb_define_method(c_cpBody, "moment_inv", rb_cpBodyGetMomentInv, 0);
  rb_define_method(c_cpBody, "v_limit", rb_cpBodyGetVLimit, 0);
  rb_define_method(c_cpBody, "w_limit", rb_cpBodyGetWLimit, 0);


  rb_define_method(c_cpBody, "mass=", rb_cpBodySetMass, 1);
  rb_define_method(c_cpBody, "moment=", rb_cpBodySetMoment, 1);
  rb_define_method(c_cpBody, "pos=", rb_cpBodySetPos, 1);
  rb_define_method(c_cpBody, "vel=", rb_cpBodySetVel, 1);
  rb_define_method(c_cpBody, "force=", rb_cpBodySetForce, 1);
  rb_define_method(c_cpBody, "angle=", rb_cpBodySetAngle, 1);
  rb_define_method(c_cpBody, "ang_vel=", rb_cpBodySetAVel, 1);
  rb_define_method(c_cpBody, "torque=", rb_cpBodySetTorque, 1);
  rb_define_method(c_cpBody, "v_limit=", rb_cpBodySetVLimit, 1);
  rb_define_method(c_cpBody, "w_limit=", rb_cpBodySetWLimit, 1);


  rb_define_method(c_cpBody, "local2world", rb_cpBodyLocal2World, 1);
  rb_define_method(c_cpBody, "world2local", rb_cpBodyWorld2Local, 1);

  rb_define_method(c_cpBody, "reset_forces", rb_cpBodyResetForces, 0);
  rb_define_method(c_cpBody, "apply_force", rb_cpBodyApplyForce, 2);
  rb_define_method(c_cpBody, "apply_impulse", rb_cpBodyApplyImpulse, 2);

  rb_define_method(c_cpBody, "update_velocity", rb_cpBodyUpdateVelocity, 3);
  rb_define_method(c_cpBody, "update_position", rb_cpBodyUpdatePosition, 1);
  rb_define_method(c_cpBody, "slew", rb_cpBodySlew, 2);

  rb_define_method(c_cpBody, "static?", rb_cpBodyIsStatic, 0);
  rb_define_method(c_cpBody, "rogue?", rb_cpBodyIsRogue, 0);
  rb_define_method(c_cpBody, "sleeping?", rb_cpBodyIsSleeping, 0);
  rb_define_method(c_cpBody, "sleep?", rb_cpBodyIsSleeping, 0);
  rb_define_method(c_cpBody, "sleep_with_self", rb_cpBodySleep, 0);
  rb_define_method(c_cpBody, "sleep_self", rb_cpBodySleep, 0);
  rb_define_method(c_cpBody, "sleep_alone", rb_cpBodySleep, 0);
  rb_define_method(c_cpBody, "sleep_with_group", rb_cpBodySleepWithGroup, 1);
  rb_define_method(c_cpBody, "sleep_group", rb_cpBodySleepWithGroup, 1);
  rb_define_method(c_cpBody, "activate", rb_cpBodyActivate, 0);
  rb_define_method(c_cpBody, "velocity_func", rb_cpBodySetVelocityFunc, -1);
  rb_define_method(c_cpBody, "position_func", rb_cpBodySetPositionFunc, -1);

  rb_define_method(c_cpBody, "object=", rb_cpBodySetData, 1);
  rb_define_method(c_cpBody, "object", rb_cpBodyGetData, 0);
  rb_define_method(c_cpBody, "kinetic_energy", rb_cpBodyKineticEnergy, 0);


}
