#!/usr/bin/env python3
"""Render the real replacement atlas at fractional zoom/edge phases on GL.

This reproduces neighboring-frame alpha bleed without opening a game or GUI.
The production Lua sampler assignment is exercised by explore_hud_smoke.lua.
"""
import ctypes as C
from pathlib import Path
import runpy
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
globals().update(runpy.run_path(str(ROOT / 'tools/tests/sea_chart_renderer_regression.py')))
atlas = Image.open(ROOT / 'bin/res/assets/Images/UI/Adventure/SeaChart/Tiles/dt_ludi.png').convert('RGBA')
assert atlas.size == (384, 384)
# GID91/local24 has a clear top row immediately below an opaque atlas frame.
# These are real pixels involved in the reproduced native horizontal seam.
for x in range(8, 56):
    assert atlas.getpixel((x, 256))[3] == 0
    assert atlas.getpixel((x, 255))[3] == 255

fbo, target, source_texture = C.c_uint(), C.c_uint(), C.c_uint()
bind(gl, 'glGenFramebuffers', None, C.c_int, C.c_void_p)(1, C.byref(fbo))
bind(gl, 'glBindFramebuffer', None, C.c_uint, C.c_uint)(0x8D40, fbo)
gl.glGenTextures(1, C.byref(target)); gl.glBindTexture(0x0DE1, target)
gl.glTexImage2D(0x0DE1, 0, 0x1908, 128, 128, 0, 0x1908, 0x1401, None)
bind(gl, 'glFramebufferTexture2D', None, C.c_uint, C.c_uint, C.c_uint, C.c_uint, C.c_int)(0x8D40, 0x8CE0, 0x0DE1, target, 0)
assert bind(gl, 'glCheckFramebufferStatus', C.c_uint, C.c_uint)(0x8D40) == 0x8CD5
gl.glGenTextures(1, C.byref(source_texture)); gl.glBindTexture(0x0DE1, source_texture)
data = atlas.tobytes()
upload = (C.c_ubyte * len(data)).from_buffer_copy(data)
gl.glTexImage2D(0x0DE1, 0, 0x1908, 384, 384, 0, 0x1908, 0x1401, upload)
for parameter in (0x2802, 0x2803): gl.glTexParameteri(0x0DE1, parameter, 0x812F)
gl.glDisable(0x0B90); gl.glDisable(0x0BC0); gl.glDisable(0x0BE2)
gl.glUseProgram(program)  # Production fog shader preserves source sample alpha.
gl.glUniformMatrix4fv(uniform_location(program, b'CC_MVPMatrix'), 1, 0, matrix)
gl.glViewport(0, 0, 128, 128); gl.glClearColor(0, 0, 0, 0)

def sample_edge(scale, phase, filter_mode):
    for parameter in (0x2801, 0x2800): gl.glTexParameteri(0x0DE1, parameter, filter_mode)
    left, top = 20.37, 80.5 + phase * scale
    right, bottom = left + 64 * scale, top - 64 * scale
    points = ((left,bottom), (right,bottom), (right,top),
              (left,bottom), (right,top), (left,top))
    pos = (C.c_float * 12)(*(component / 64 - 1 for point in points for component in point))
    # Unmodified full tile UVs and native full-size geometry; no inset or mask erosion.
    uv = (C.c_float * 12)(0,320/384, 64/384,320/384, 64/384,256/384,
                         0,320/384, 64/384,256/384, 0,256/384)
    attrib_pointer(0, 2, 0x1406, 0, 0, pos); attrib_pointer(2, 2, 0x1406, 0, 0, uv)
    gl.glClear(0x4000); gl.glDrawArrays(4, 0, 6)
    result = (C.c_ubyte * 4)()
    gl.glReadPixels(int((left+right)/2), 80, 1, 1, 0x1908, 0x1401, result)
    return result[3]

cases = 0
for scale in (.225, .3, .6, .675, .8, .84375, 1):
    for phase in (.05, .15, .3, .49):
        linear = sample_edge(scale, phase, 0x2601)
        nearest = sample_edge(scale, phase, 0x2600)
        assert linear > 0, ('fixture must expose neighboring-frame bleed', scale, phase, linear)
        assert nearest == 0, ('clear tile edge acquired alpha', scale, phase, nearest)
        assert abs(linear - (0.5-phase)*255) <= 3, (scale, phase, linear)
        cases += 1
print('PASS actual replacement-atlas GL sampling: %d fractional-scale/edge cases reproduce linear alpha bleed and retain clear original tile edges with nearest' % cases)
