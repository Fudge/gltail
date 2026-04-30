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

extern VALUE m_Chipmunk;

extern VALUE c_cpVect;
extern VALUE c_cpBB;
extern VALUE c_cpBody;
extern VALUE m_cpShape;
extern VALUE c_cpCircleShape;
extern VALUE c_cpSegmentShape;
extern VALUE c_cpPolyShape;
extern VALUE m_cpConstraint;
extern VALUE c_cpSpace;
extern VALUE c_cpArbiter;
extern VALUE c_cpStaticBody;
extern VALUE c_cpSegmentQueryInfo;

extern ID id_parent;

static inline VALUE
VNEW(cpVect v) {
  cpVect *ptr = malloc(sizeof(cpVect));
  *ptr = v;
  return Data_Wrap_Struct(c_cpVect, NULL, free, ptr);
}

static inline VALUE
VWRAP(VALUE parent, cpVect *v) {
  VALUE vec_obj = Data_Wrap_Struct(c_cpVect, NULL, NULL, v);
  rb_ivar_set(vec_obj, id_parent, parent);

  return vec_obj;
}

#define GETTER_TEMPLATE(func_name, klass, type)                                                                            \
  static inline type *                                                                                                     \
  func_name(VALUE self)                                                                                                    \
  {                                                                                                                        \
    if(!rb_obj_is_kind_of(self, klass)) {                                                                                  \
      VALUE klass_name = rb_funcall(klass, rb_intern("to_s"), 0);                                                          \
      rb_raise(rb_eTypeError, "wrong argument type %s (expected %s)", rb_obj_classname(self), StringValuePtr(klass_name)); \
    }                                                                                                                      \
    type *ptr = NULL;                                                                                                      \
    Data_Get_Struct(self, type, ptr);                                                                                      \
    return ptr;                                                                                                            \
  }                                                                                                                        \

GETTER_TEMPLATE(VGET, c_cpVect, cpVect )
GETTER_TEMPLATE(BBGET, c_cpBB, cpBB   )
GETTER_TEMPLATE(BODY, c_cpBody, cpBody )
GETTER_TEMPLATE(STATICBODY, c_cpStaticBody, cpBody)
GETTER_TEMPLATE(SHAPE, m_cpShape, cpShape)
GETTER_TEMPLATE(CONSTRAINT, m_cpConstraint, cpConstraint)
GETTER_TEMPLATE(SPACE, c_cpSpace, cpSpace)
GETTER_TEMPLATE(ARBITER, c_cpArbiter, cpArbiter)
/* GETTER_TEMPLATE(SPACEHASH, c_cpSpaceHash, cpSpaceHash) */

// Helper to wrap cpArbter objects.
VALUE ARBWRAP(cpArbiter *arb);

// Like vget, but returns a zero vector if value is nil, and
// it also does not need to be dereferenced.
static inline cpVect
VGET_ZERO(VALUE value) {
  if(NIL_P(value)) return cpvzero;
  return *VGET(value);
}

//Helper that allocates and initializes a SegmenQueryInfo struct
VALUE rb_cpSegmentQueryInfoNew(VALUE shape, VALUE t, VALUE n);

// Helper that allocates and initializes a ContactPoint struct.
VALUE rb_cpContactPointNew(VALUE point, VALUE normal, VALUE dist);


void Init_chipmunk(void);
void Init_cpVect();
void Init_cpBB();
void Init_cpBody();
void Init_cpShape();
void Init_cpConstraint();
void Init_cpSpace();
void Init_cpArbiter(void);

// transforms a boolean VALUE to an int
#define CP_BOOL_INT(VAL) (((VAL) == Qnil) || ((VAL) == Qfalse) ? 0 : 1)

// transforms a C value (pointer or int) to Qtrue of Qfalse
// For consistency with CP_BOOL_INT.
#define CP_INT_BOOL(VAL) ((VAL) ? Qtrue : Qfalse)






