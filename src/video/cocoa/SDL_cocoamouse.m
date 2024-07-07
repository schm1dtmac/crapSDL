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
#include "../../SDL_internal.h"

#ifdef SDL_VIDEO_DRIVER_COCOA

#include "SDL_events.h"
#include "SDL_cocoamouse.h"
#include "SDL_cocoavideo.h"

#include "../../events/SDL_mouse_c.h"

/* #define DEBUG_COCOAMOUSE */

#ifdef DEBUG_COCOAMOUSE
#define DLog(fmt, ...) printf("%s: " fmt "\n", __func__, ##__VA_ARGS__)
#else
#define DLog(...) do { } while (0)
#endif


static SDL_Cursor *Cocoa_CreateDefaultCursor()
{ @autoreleasepool
{
    return NULL;
}}

static SDL_Cursor *Cocoa_CreateCursor(SDL_Surface * surface, int hot_x, int hot_y)
{ @autoreleasepool
{
    return NULL;
}}


static SDL_Cursor *Cocoa_CreateSystemCursor(SDL_SystemCursor id)
{ @autoreleasepool
{
    return NULL;
}}

static void Cocoa_FreeCursor(SDL_Cursor * cursor)
{ @autoreleasepool
{
    return;
}}

static int Cocoa_ShowCursor(SDL_Cursor * cursor)
{ @autoreleasepool
{
    return 0;
}}

static SDL_Window *SDL_FindWindowAtPoint(const int x, const int y)
{
    const SDL_Point pt = { x, y };
    SDL_Window *i;
    for (i = SDL_GetVideoDevice()->windows; i; i = i->next) {
        const SDL_Rect r = { i->x, i->y, i->w, i->h };
        if (SDL_PointInRect(&pt, &r)) {
            return i;
        }
    }

    return NULL;
}

static int Cocoa_WarpMouseGlobal(int x, int y)
{
    return 0;
}

static void Cocoa_WarpMouse(SDL_Window * window, int x, int y)
{
    return;
}

static int Cocoa_SetRelativeMouseMode(SDL_bool enabled)
{
    return 0;
}

static int Cocoa_CaptureMouse(SDL_Window *window)
{
    /* our Cocoa event code already tracks the mouse outside the window,
        so all we have to do here is say "okay" and do what we always do. */
    return 0;
}

static Uint32 Cocoa_GetGlobalMouseState(int *x, int *y)
{
    const NSUInteger cocoaButtons = [NSEvent pressedMouseButtons];
    const NSPoint cocoaLocation = [NSEvent mouseLocation];
    Uint32 retval = 0;

    *x = (int) cocoaLocation.x;
    *y = (int) (CGDisplayPixelsHigh(kCGDirectMainDisplay) - cocoaLocation.y);

    retval |= (cocoaButtons & (1 << 0)) ? SDL_BUTTON_LMASK : 0;
    retval |= (cocoaButtons & (1 << 1)) ? SDL_BUTTON_RMASK : 0;
    retval |= (cocoaButtons & (1 << 2)) ? SDL_BUTTON_MMASK : 0;
    retval |= (cocoaButtons & (1 << 3)) ? SDL_BUTTON_X1MASK : 0;
    retval |= (cocoaButtons & (1 << 4)) ? SDL_BUTTON_X2MASK : 0;

    return retval;
}

int Cocoa_InitMouse(_THIS)
{
    return 0;
}

static void Cocoa_HandleTitleButtonEvent(_THIS, NSEvent *event)
{
    SDL_Window *window;
    NSWindow *nswindow = [event window];

    /* You might land in this function before SDL_Init if showing a message box.
       Don't derefence a NULL pointer if that happens. */
    if (_this == NULL) {
        return;
    }

    for (window = _this->windows; window; window = window->next) {
        SDL_WindowData *data = (__bridge SDL_WindowData *)window->driverdata;
        if (data && data.nswindow == nswindow) {
            switch ([event type]) {
            case NSEventTypeLeftMouseDown:
            case NSEventTypeRightMouseDown:
            case NSEventTypeOtherMouseDown:
                [data.listener setFocusClickPending:[event buttonNumber]];
                break;
            case NSEventTypeLeftMouseUp:
            case NSEventTypeRightMouseUp:
            case NSEventTypeOtherMouseUp:
                [data.listener clearFocusClickPending:[event buttonNumber]];
                break;
            default:
                break;
            }
            break;
        }
    }
}

void Cocoa_HandleMouseEvent(_THIS, NSEvent *event)
{
    SDL_Mouse *mouse;
    SDL_MouseData *driverdata;
    SDL_MouseID mouseID;
    NSPoint location;
    CGFloat lastMoveX, lastMoveY;
    float deltaX, deltaY;
    SDL_bool seenWarp;
    switch ([event type]) {
        case NSEventTypeMouseMoved:
        case NSEventTypeLeftMouseDragged:
        case NSEventTypeRightMouseDragged:
        case NSEventTypeOtherMouseDragged:
            break;

        case NSEventTypeLeftMouseDown:
        case NSEventTypeLeftMouseUp:
        case NSEventTypeRightMouseDown:
        case NSEventTypeRightMouseUp:
        case NSEventTypeOtherMouseDown:
        case NSEventTypeOtherMouseUp:
            if ([event window]) {
                NSRect windowRect = [[[event window] contentView] frame];
                if (!NSMouseInRect([event locationInWindow], windowRect, NO)) {
                    Cocoa_HandleTitleButtonEvent(_this, event);
                    return;
                }
            }
            return;

        default:
            /* Ignore any other events. */
            return;
    }

    mouse = SDL_GetMouse();
    driverdata = (SDL_MouseData*)mouse->driverdata;
    if (!driverdata) {
        return;  /* can happen when returning from fullscreen Space on shutdown */
    }

    mouseID = mouse ? mouse->mouseID : 0;
    seenWarp = driverdata->seenWarp;
    driverdata->seenWarp = NO;

    if (driverdata->justEnabledRelative) {
        driverdata->justEnabledRelative = SDL_FALSE;
        return;  // dump the first event back.
    }

    location =  [NSEvent mouseLocation];
    lastMoveX = driverdata->lastMoveX;
    lastMoveY = driverdata->lastMoveY;
    driverdata->lastMoveX = location.x;
    driverdata->lastMoveY = location.y;
    DLog("Last seen mouse: (%g, %g)", location.x, location.y);

    /* Non-relative movement is handled in -[Cocoa_WindowListener mouseMoved:] */
    if (!mouse->relative_mode) {
        return;
    }

    /* Ignore events that aren't inside the client area (i.e. title bar.) */
    if ([event window]) {
        NSRect windowRect = [[[event window] contentView] frame];
        if (!NSMouseInRect([event locationInWindow], windowRect, NO)) {
            return;
        }
    }

    deltaX = [event deltaX];
    deltaY = [event deltaY];

    if (seenWarp) {
        deltaX += (lastMoveX - driverdata->lastWarpX);
        deltaY += ((CGDisplayPixelsHigh(kCGDirectMainDisplay) - lastMoveY) - driverdata->lastWarpY);

        DLog("Motion was (%g, %g), offset to (%g, %g)", [event deltaX], [event deltaY], deltaX, deltaY);
    }

    SDL_SendMouseMotion(mouse->focus, mouseID, 1, (int)deltaX, (int)deltaY);
}

void Cocoa_HandleMouseWheel(SDL_Window *window, NSEvent *event)
{
    SDL_MouseID mouseID;
    SDL_MouseWheelDirection direction;
    CGFloat x, y;
    SDL_Mouse *mouse = SDL_GetMouse();
    if (!mouse) {
        return;
    }

    mouseID = mouse->mouseID;
    x = -[event deltaX];
    y = [event deltaY];
    direction = SDL_MOUSEWHEEL_NORMAL;

    if ([event isDirectionInvertedFromDevice] == YES) {
        direction = SDL_MOUSEWHEEL_FLIPPED;
    }

    /* For discrete scroll events from conventional mice, always send a full tick.
       For continuous scroll events from trackpads, send fractional deltas for smoother scrolling. */
    if (![event hasPreciseScrollingDeltas]) {
        if (x > 0) {
            x = SDL_ceil(x);
        } else if (x < 0) {
            x = SDL_floor(x);
        }
        if (y > 0) {
            y = SDL_ceil(y);
        } else if (y < 0) {
            y = SDL_floor(y);
        }
    }

    SDL_SendMouseWheel(window, mouseID, x, y, direction);
}

void Cocoa_HandleMouseWarp(CGFloat x, CGFloat y)
{
    /* This makes Cocoa_HandleMouseEvent ignore the delta caused by the warp,
     * since it gets included in the next movement event.
     */
    SDL_MouseData *driverdata = (SDL_MouseData*)SDL_GetMouse()->driverdata;
    driverdata->lastWarpX = x;
    driverdata->lastWarpY = y;
    driverdata->seenWarp = SDL_TRUE;

    DLog("(%g, %g)", x, y);
}

void Cocoa_QuitMouse(_THIS)
{
    SDL_Mouse *mouse = SDL_GetMouse();
    if (mouse) {
        if (mouse->driverdata) {
            SDL_free(mouse->driverdata);
            mouse->driverdata = NULL;
        }
    }
}

#endif /* SDL_VIDEO_DRIVER_COCOA */

/* vi: set ts=4 sw=4 expandtab: */
