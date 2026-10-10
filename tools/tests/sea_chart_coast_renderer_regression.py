#!/usr/bin/env python3
"""Run production coast GLSL on Mesa, using only original-atlas alpha.

This is a render regression, not asset creation. No game, GUI, save, or output
image is opened or modified. The alpha masks below model the runtime GPU union.
"""
import ctypes as C
from pathlib import Path
import re
import runpy
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
# Reuse the established surfaceless GL setup and its fog/grid/stencil checks.
globals().update(runpy.run_path(str(ROOT / 'tools/tests/sea_chart_renderer_regression.py')))
source = (ROOT / 'bin/res/scripts/LuaClass/SeaChartWorldTheme.lua').read_text()
vertex = re.search(r'W\.coastVertexShader = \[\[(.*?)\]\]', source, re.S).group(1)
fragment = re.search(r'W\.coastFragmentShader = \[\[(.*?)\]\]', source, re.S).group(1)
mask_fragment = re.search(r'W\.coastMaskFragmentShader = \[\[(.*?)\]\]', source, re.S).group(1)

def make_program(body):
    program = gl.glCreateProgram()
    shader_vertex = vertex if body == mask_fragment else vertex.replace('CC_MVPMatrix', 'CC_PMatrix')
    attach(program, compile_stage(0x8B31, 'uniform mat4 CC_MVPMatrix;\nuniform mat4 CC_PMatrix;\n' + shader_vertex))
    attach(program, compile_stage(0x8B30, body))
    for index, name in enumerate([b'a_position', b'a_color', b'a_texCoord']):
        attribute_location(program, index, name)
    gl.glLinkProgram(program)
    linked = C.c_int()
    gl.glGetProgramiv(program, 0x8B82, C.byref(linked))
    assert linked.value, 'coast shader did not link'
    gl.glUseProgram(program)
    gl.glUniformMatrix4fv(uniform_location(program, b'CC_MVPMatrix'), 1, 0, matrix)
    gl.glUniformMatrix4fv(uniform_location(program, b'CC_PMatrix'), 1, 0, matrix)
    gl.glUniform1i(uniform_location(program, b'CC_Texture0'), 0)
    return program

coast_program = make_program(fragment)
# The renderer supplies transformed sprite vertices. A nonidentity model-view
# must not scale/translate them again in the final coast sprite shader.
double_transform = (C.c_float * 16)(4,0,0,0, 0,4,0,0, 0,0,1,0, .8,.5,0,1)
gl.glUniformMatrix4fv(uniform_location(coast_program, b'CC_MVPMatrix'), 1, 0, double_transform)
make_program(mask_fragment)
fbo, target_texture, source_texture = C.c_uint(), C.c_uint(), C.c_uint()
bind(gl, 'glGenFramebuffers', None, C.c_int, C.c_void_p)(1, C.byref(fbo))
bind(gl, 'glBindFramebuffer', None, C.c_uint, C.c_uint)(0x8D40, fbo)
gl.glGenTextures(1, C.byref(target_texture))
gl.glBindTexture(0x0DE1, target_texture)
gl.glTexImage2D(0x0DE1, 0, 0x1908, 1024, 1024, 0, 0x1908, 0x1401, None)
gl.glTexParameteri(0x0DE1, 0x2801, 0x2601)
gl.glTexParameteri(0x0DE1, 0x2800, 0x2601)
bind(gl, 'glFramebufferTexture2D', None, C.c_uint, C.c_uint, C.c_uint, C.c_uint, C.c_int)(0x8D40, 0x8CE0, 0x0DE1, target_texture, 0)
assert bind(gl, 'glCheckFramebufferStatus', C.c_uint, C.c_uint)(0x8D40) == 0x8CD5
gl.glGenTextures(1, C.byref(source_texture))
gl.glBindTexture(0x0DE1, source_texture)
for key in (0x2801, 0x2800): gl.glTexParameteri(0x0DE1, key, 0x2601)
for key in (0x2802, 0x2803): gl.glTexParameteri(0x0DE1, key, 0x812F)
gl.glDisable(0x0B90)
gl.glDisable(0x0BC0)
gl.glDisable(0x0BE2)
gl.glViewport(0, 0, 1024, 1024)
gl.glClearColor(0, 0, 0, 0)
gl.glUseProgram(coast_program)
# The other test leaves the same six-vertex quad and full-rectangle UV bound.

def render(data):
    upload = (C.c_ubyte * len(data)).from_buffer_copy(data)
    gl.glTexImage2D(0x0DE1, 0, 0x1908, 256, 256, 0, 0x1908, 0x1401, upload)
    gl.glClear(0x4000)
    gl.glDrawArrays(4, 0, 6)
    result = (C.c_ubyte * (1024 * 1024 * 4))()
    gl.glReadPixels(0, 0, 1024, 1024, 0x1908, 0x1401, result)
    return bytes(result)

def pixel(result, x, y):
    return result[(y*1024+x)*4:(y*1024+x+1)*4]

# An opaque continent crossing every tile and chunk edge has no fake shores.
solid = render(bytes([214, 196, 115, 255]) * (256*256))
assert not any(solid), 'opaque land interior acquired a false coast'
empty = render(bytes(256*256*4))
assert not any(empty), 'open water acquired false coast centers'

alpha = Image.open(ROOT / 'bin/res/assets/Images/Map/dt_senlin.png').convert('RGBA').getchannel('A')
# This genuine 3x3 rounded island is stored at atlas columns 3..5, rows 0..2.
# Place it across the 960px core boundary; every source alpha sample is original.
def original_mask(origin_x):
    data = bytearray()
    for yy in range(256):
        wy = yy*4+2-32
        for xx in range(256):
            wx = origin_x+xx*4+2-32
            ix, iy = wx-880, 191-(wy-384)
            a = alpha.getpixel((192+ix, iy)) if 0 <= ix < 192 and 0 <= iy < 192 else 0
            data.extend((round(214*a/255), round(196*a/255), round(115*a/255), a))
    return data

left, right = render(original_mask(0)), render(original_mask(960))
assert pixel(left, 960+32, 480+32)[3] == 0, 'joined original opaque tiles received an interior grid edge'
assert pixel(left, 840+32, 480+32)[3] == 0, 'shore effect reached distant water'
assert pixel(right, 140, 512)[3] == 0, 'shore effect reached distant right-hand water'
# Compare both independently rendered gutter views at the SAME world pixels.
# Samples are at least 16px from either mask edge, so all neighbors are present.
maximum = 0
for wy in range(365, 595):
    for wx in range(945, 975):
        a, b = pixel(left, wx+32, wy+32), pixel(right, wx-960+32, wy+32)
        maximum = max(maximum, max(abs(x-y) for x,y in zip(a,b)))
assert maximum <= 2, ('chunk seam or discontinuous foam phase', maximum)
# The original rounded shoreline produces visible shallows AND an inner ledge.
water, land_edge, foam = 0, 0, 0
for wy in range(365, 595):
    for wx in range(850, 975):
        out = pixel(left, wx+32, wy+32)
        ix, iy = wx-880, 191-(wy-384)
        original = alpha.getpixel((192+ix, iy)) if 0 <= ix < 192 and 0 <= iy < 192 else 0
        if out[3] > 12:
            if original < 32: water += 1
            if original > 230: land_edge += 1
            if original < 128 and out[0] > out[3] * .55: foam += 1
assert water > 500 and land_edge > 300 and foam > 40, (water, land_edge, foam)
print('PASS original-alpha coast GLSL: real shallow-water rim, inner ledge, broken foam, clear water/land centers, seamless 960px chunk join (max delta %d)' % maximum)

# Verify the opaque-interior shortcut against the complete previous equation,
# including the former duplicate center-alpha sample. This is byte equivalence
# on the actual GL output, not an assertion that merely mirrors the condition.
reference_fragment, shortcuts = re.subn(
    r'// OPAQUE_INTERIOR_EARLY_RETURN_BEGIN.*?// OPAQUE_INTERIOR_EARLY_RETURN_END',
    '', fragment, flags=re.S)
assert shortcuts == 1
reference_fragment = reference_fragment.replace('float a = smoothstep(0.22, 0.78, source.a);', 'float a = land(p);')
reference_program = make_program(reference_fragment)
for mask, expected in ((original_mask(0), left), (original_mask(960), right),
                       (bytes([214,196,115,255])*(256*256), solid), (bytes(256*256*4), empty)):
    assert render(mask) == expected, 'opaque-interior shortcut changed a coast pixel'
print('PASS opaque-interior shortcut: pixel-identical to full 22-tap equation for original coast, opaque land, open water and chunk overlap')

# Also compile/link against an actual GLES2 context. Desktop GLSL alone cannot
# catch fragment precision/varying mismatches on the older mobile render path.
assert egl.eglBindAPI(0x30A0)  # EGL_OPENGL_ES_API
es_attributes = (C.c_int * 13)(0x3033, 1, 0x3040, 4, 0x3024, 8, 0x3023, 8, 0x3022, 8, 0x3021, 8, 0x3038)
es_config, es_count = C.c_void_p(), C.c_int()
assert choose(display, es_attributes, C.byref(es_config), 1, C.byref(es_count)) and es_count.value
es_surface = egl.eglCreatePbufferSurface(display, es_config, surface_attributes)
es_context_attributes = (C.c_int * 3)(0x3098, 2, 0x3038)
es_context = egl.eglCreateContext(display, es_config, None, es_context_attributes)
assert es_surface and es_context
assert egl.eglMakeCurrent(display, es_surface, es_surface, es_context)
make_program(mask_fragment)
make_program(fragment)
print('PASS production coast mask and edge shaders compile/link in GLES2 with matching varying precision')
