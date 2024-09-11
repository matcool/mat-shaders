#ifndef _H_OPTIONS_
#define _H_OPTIONS_

const bool shadowHardwareFiltering = true;

const float ambientOcclusionLevel = 0.8; // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
const int shadowMapResolution = 1024; // [512 1024 2048 4096 8192]
const float sunPathRotation = -30.0; // [-45.0 -30.0 -15.0 0.0 15.0 30.0 45.0]

#define SHADOW_DISTORT_FACTOR 0.08 // [0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1]
#define ENABLE_SHADOW_DISTORT

//#define ENABLE_EASTER_EGG

#endif // _H_OPTIONS_
