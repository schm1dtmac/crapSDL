/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2024 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
#ifndef SDL_internal_h_
#define SDL_internal_h_

/* Many of SDL's features require _GNU_SOURCE on various platforms */
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

/* This is for a variable-length array at the end of a struct:
    struct x { int y; char z[SDL_VARIABLE_LENGTH_ARRAY]; };
   Use this because GCC 2 needs different magic than other compilers. */
#if (defined(__GNUC__) && (__GNUC__ <= 2)) || defined(__CC_ARM) || defined(__cplusplus)
#define SDL_VARIABLE_LENGTH_ARRAY 1
#else
#define SDL_VARIABLE_LENGTH_ARRAY
#endif

#define SDL_MAX_SMALL_ALLOC_STACKSIZE          128
#define SDL_small_alloc(type, count, pisstack) ((*(pisstack) = ((sizeof(type) * (count)) < SDL_MAX_SMALL_ALLOC_STACKSIZE)), (*(pisstack) ? SDL_stack_alloc(type, count) : (type *)SDL_malloc(sizeof(type) * (count))))
#define SDL_small_free(ptr, isstack) \
    if ((isstack)) {                 \
        SDL_stack_free(ptr);         \
    } else {                         \
        SDL_free(ptr);               \
    }

#include "SDL_config.h"

/* If you run into a warning that O_CLOEXEC is redefined, update the SDL configuration header for your platform to add HAVE_O_CLOEXEC */
#ifndef HAVE_O_CLOEXEC
#define O_CLOEXEC 0
#endif

#ifndef SDL_RENDER_DISABLED
/* define the not defined ones as 0 */
#ifndef SDL_VIDEO_RENDER_D3D
#define SDL_VIDEO_RENDER_D3D 0
#endif
#ifndef SDL_VIDEO_RENDER_D3D11
#define SDL_VIDEO_RENDER_D3D11 0
#endif
#ifndef SDL_VIDEO_RENDER_D3D12
#define SDL_VIDEO_RENDER_D3D12 0
#endif
#ifndef SDL_VIDEO_RENDER_METAL
#define SDL_VIDEO_RENDER_METAL 0
#endif
#ifndef SDL_VIDEO_RENDER_OGL
#define SDL_VIDEO_RENDER_OGL  0
#endif
#ifndef SDL_VIDEO_RENDER_OGL_ES
#define SDL_VIDEO_RENDER_OGL_ES 0
#endif
#ifndef SDL_VIDEO_RENDER_OGL_ES2
#define SDL_VIDEO_RENDER_OGL_ES2 0
#endif
#ifndef SDL_VIDEO_RENDER_DIRECTFB
#define SDL_VIDEO_RENDER_DIRECTFB 0
#endif
#ifndef SDL_VIDEO_RENDER_PS2
#define SDL_VIDEO_RENDER_PS2 0
#endif
#ifndef SDL_VIDEO_RENDER_PSP
#define SDL_VIDEO_RENDER_PSP 0
#endif
#ifndef SDL_VIDEO_RENDER_VITA_GXM
#define SDL_VIDEO_RENDER_VITA_GXM 0
#endif
#else /* define all as 0 */
#undef SDL_VIDEO_RENDER_SW
#define SDL_VIDEO_RENDER_SW 0
#undef SDL_VIDEO_RENDER_D3D
#define SDL_VIDEO_RENDER_D3D 0
#undef SDL_VIDEO_RENDER_D3D11
#define SDL_VIDEO_RENDER_D3D11 0
#undef SDL_VIDEO_RENDER_D3D12
#define SDL_VIDEO_RENDER_D3D12 0
#undef SDL_VIDEO_RENDER_METAL
#define SDL_VIDEO_RENDER_METAL 0
#undef SDL_VIDEO_RENDER_OGL
#define SDL_VIDEO_RENDER_OGL  0
#undef SDL_VIDEO_RENDER_OGL_ES
#define SDL_VIDEO_RENDER_OGL_ES 0
#undef SDL_VIDEO_RENDER_OGL_ES2
#define SDL_VIDEO_RENDER_OGL_ES2 0
#undef SDL_VIDEO_RENDER_DIRECTFB
#define SDL_VIDEO_RENDER_DIRECTFB 0
#undef SDL_VIDEO_RENDER_PS2
#define SDL_VIDEO_RENDER_PS2 0
#undef SDL_VIDEO_RENDER_PSP
#define SDL_VIDEO_RENDER_PSP 0
#undef SDL_VIDEO_RENDER_VITA_GXM
#define SDL_VIDEO_RENDER_VITA_GXM 0
#endif /* SDL_RENDER_DISABLED */

#define SDL_HAS_RENDER_DRIVER \
       (SDL_VIDEO_RENDER_SW       | \
        SDL_VIDEO_RENDER_D3D      | \
        SDL_VIDEO_RENDER_D3D11    | \
        SDL_VIDEO_RENDER_D3D12    | \
        SDL_VIDEO_RENDER_METAL    | \
        SDL_VIDEO_RENDER_OGL      | \
        SDL_VIDEO_RENDER_OGL_ES   | \
        SDL_VIDEO_RENDER_OGL_ES2  | \
        SDL_VIDEO_RENDER_DIRECTFB | \
        SDL_VIDEO_RENDER_PS2      | \
        SDL_VIDEO_RENDER_PSP      | \
        SDL_VIDEO_RENDER_VITA_GXM)

#if !defined(SDL_RENDER_DISABLED) && !SDL_HAS_RENDER_DRIVER
#error SDL_RENDER enabled without any backend drivers.
#endif

#include "SDL_assert.h"
#include "SDL_log.h"

#endif /* SDL_internal_h_ */

/* vi: set ts=4 sw=4 expandtab: */
