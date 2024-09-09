#ifndef _H_DEBUG_
#define _H_DEBUG_

vec4 _DEBUG_COLOR_(vec4 v) { return v; }
vec4 _DEBUG_COLOR_(vec3 v) { return vec4(v, 1.0); }
vec4 _DEBUG_COLOR_(float v) { return vec4(vec3(v), 1.0); }

#define DEBUG_COLOR(value) outColor0 = _DEBUG_COLOR_(value); return

#endif
