#!/usr/bin/env python3
"""Exercise the production fog shader on a surfaceless Mesa GL context.

No game process, window, input device or save is opened. This catches actual
shader/blending defects that a Lua API mock cannot establish.
"""
import ctypes as C
from pathlib import Path
import re
from PIL import Image

root = Path(__file__).resolve().parents[2]
source = (root / "bin/res/scripts/LuaClass/SeaChartTheme.lua").read_text()
vertex = re.search(r"S\.fogVertexShader = \[\[(.*?)\]\]", source, re.S).group(1)
fragment = re.search(r"S\.fogFragmentShader = \[\[(.*?)\]\]", source, re.S).group(1)
egl = C.CDLL("libEGL.so.1")
gl = C.CDLL("libGL.so.1")


def bind(lib, name, result, *args):
    fn = getattr(lib, name)
    fn.restype, fn.argtypes = result, args
    return fn


get_proc = bind(egl, "eglGetProcAddress", C.c_void_p, C.c_char_p)
get_display = C.CFUNCTYPE(C.c_void_p, C.c_uint, C.c_void_p, C.POINTER(C.c_int))(
    get_proc(b"eglGetPlatformDisplayEXT")
)
display = get_display(0x31DD, None, None)  # EGL_PLATFORM_SURFACELESS_MESA
initialize = bind(egl, "eglInitialize", C.c_uint, C.c_void_p, C.c_void_p, C.c_void_p)
assert initialize(display, None, None), "surfaceless EGL initialization failed"
assert bind(egl, "eglBindAPI", C.c_uint, C.c_uint)(0x30A2)  # EGL_OPENGL_API
choose = bind(egl, "eglChooseConfig", C.c_uint, C.c_void_p, C.c_void_p, C.c_void_p, C.c_int, C.c_void_p)
attributes = (C.c_int * 17)(0x3033, 1, 0x3040, 8, 0x3024, 8, 0x3023, 8, 0x3022, 8, 0x3021, 8, 0x3025, 0, 0x3026, 8, 0x3038)
config, count = C.c_void_p(), C.c_int()
assert choose(display, attributes, C.byref(config), 1, C.byref(count)) and count.value
surface_attributes = (C.c_int * 5)(0x3057, 2, 0x3056, 2, 0x3038)
surface = bind(egl, "eglCreatePbufferSurface", C.c_void_p, C.c_void_p, C.c_void_p, C.c_void_p)(display, config, surface_attributes)
context = bind(egl, "eglCreateContext", C.c_void_p, C.c_void_p, C.c_void_p, C.c_void_p, C.c_void_p)(display, config, None, None)
assert surface and context
assert bind(egl, "eglMakeCurrent", C.c_uint, C.c_void_p, C.c_void_p, C.c_void_p, C.c_void_p)(display, surface, surface, context)

create_shader = bind(gl, "glCreateShader", C.c_uint, C.c_uint)
shader_source = bind(gl, "glShaderSource", None, C.c_uint, C.c_int, C.c_void_p, C.c_void_p)
compile_shader = bind(gl, "glCompileShader", None, C.c_uint)
shader_iv = bind(gl, "glGetShaderiv", None, C.c_uint, C.c_uint, C.c_void_p)
shader_log = bind(gl, "glGetShaderInfoLog", None, C.c_uint, C.c_int, C.c_void_p, C.c_void_p)


def compile_stage(kind, text):
    stage = create_shader(kind)
    strings = (C.c_char_p * 1)(text.encode())
    shader_source(stage, 1, strings, None)
    compile_shader(stage)
    ok = C.c_int()
    shader_iv(stage, 0x8B81, C.byref(ok))
    log = C.create_string_buffer(4096)
    shader_log(stage, len(log), None, log)
    assert ok.value, log.value.decode()
    return stage


# Cocos prepends its built-in matrix uniforms before compiling.
vert = compile_stage(0x8B31, "uniform mat4 CC_MVPMatrix;\n" + vertex)
frag = compile_stage(0x8B30, fragment)
program = bind(gl, "glCreateProgram", C.c_uint)()
attach = bind(gl, "glAttachShader", None, C.c_uint, C.c_uint)
attach(program, vert)
attach(program, frag)
attribute_location = bind(gl, "glBindAttribLocation", None, C.c_uint, C.c_uint, C.c_char_p)
for index, name in enumerate([b"a_position", b"a_color", b"a_texCoord"]):
    attribute_location(program, index, name)
bind(gl, "glLinkProgram", None, C.c_uint)(program)
linked = C.c_int()
bind(gl, "glGetProgramiv", None, C.c_uint, C.c_uint, C.c_void_p)(program, 0x8B82, C.byref(linked))
assert linked.value, "production fog shader did not link"
bind(gl, "glUseProgram", None, C.c_uint)(program)
uniform_location = bind(gl, "glGetUniformLocation", C.c_int, C.c_uint, C.c_char_p)
matrix = (C.c_float * 16)(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
bind(gl, "glUniformMatrix4fv", None, C.c_int, C.c_int, C.c_ubyte, C.c_void_p)(uniform_location(program, b"CC_MVPMatrix"), 1, 0, matrix)
bind(gl, "glUniform1i", None, C.c_int, C.c_int)(uniform_location(program, b"CC_Texture0"), 0)

texture = C.c_uint()
bind(gl, "glGenTextures", None, C.c_int, C.c_void_p)(1, C.byref(texture))
bind(gl, "glBindTexture", None, C.c_uint, C.c_uint)(0x0DE1, texture)
tex_parameter = bind(gl, "glTexParameteri", None, C.c_uint, C.c_uint, C.c_int)
tex_parameter(0x0DE1, 0x2801, 0x2600)
tex_parameter(0x0DE1, 0x2800, 0x2600)
# Black RGB matches the original fog. Alpha covers clear, half and full fog.
pixels = (C.c_ubyte * 16)(0, 0, 0, 0, 0, 0, 0, 128, 0, 0, 0, 255, 0, 0, 0, 255)
bind(gl, "glTexImage2D", None, C.c_uint, C.c_int, C.c_int, C.c_int, C.c_int, C.c_int, C.c_uint, C.c_uint, C.c_void_p)(0x0DE1, 0, 0x1908, 2, 2, 0, 0x1908, 0x1401, pixels)
positions = (C.c_float * 12)(-1, -1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1)
uv = (C.c_float * 12)(0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1)
attrib_pointer = bind(gl, "glVertexAttribPointer", None, C.c_uint, C.c_int, C.c_uint, C.c_ubyte, C.c_int, C.c_void_p)
enable_attrib = bind(gl, "glEnableVertexAttribArray", None, C.c_uint)
attrib_pointer(0, 2, 0x1406, 0, 0, positions)
attrib_pointer(2, 2, 0x1406, 0, 0, uv)
enable_attrib(0)
enable_attrib(2)
bind(gl, "glVertexAttrib4f", None, C.c_uint, C.c_float, C.c_float, C.c_float, C.c_float)(1, 1, 1, 1, 1)
bind(gl, "glViewport", None, C.c_int, C.c_int, C.c_int, C.c_int)(0, 0, 2, 2)
bind(gl, "glClearColor", None, C.c_float, C.c_float, C.c_float, C.c_float)(20/255, 80/255, 130/255, 1)
bind(gl, "glClear", None, C.c_uint)(0x4000)
bind(gl, "glEnable", None, C.c_uint)(0x0BE2)
bind(gl, "glBlendFunc", None, C.c_uint, C.c_uint)(1, 771)
bind(gl, "glDrawArrays", None, C.c_uint, C.c_int, C.c_int)(4, 0, 6)
result = (C.c_ubyte * 16)()
bind(gl, "glReadPixels", None, C.c_int, C.c_int, C.c_int, C.c_int, C.c_uint, C.c_uint, C.c_void_p)(0, 0, 2, 2, 0x1908, 0x1401, result)
actual = [tuple(result[i:i+4]) for i in range(0, 16, 4)]
expected = [(20, 80, 130, 255), (11, 57, 91, 255), (3, 35, 52, 255), (3, 35, 52, 255)]
for got, wanted in zip(actual, expected):
    assert all(abs(a-b) <= 1 for a, b in zip(got, wanted)), (actual, expected)
print("PASS production fog shader on surfaceless GL: transparent tiles stay clear, partial alpha blends, full fog is ink blue")

grid_fragment = re.search(r"S\.gridFragmentShader = \[\[(.*?)\]\]", source, re.S).group(1)
grid_frag = compile_stage(0x8B30, grid_fragment)
grid_program = bind(gl, "glCreateProgram", C.c_uint)()
attach(grid_program, vert)
attach(grid_program, grid_frag)
for index, name in enumerate([b"a_position", b"a_color", b"a_texCoord"]):
    attribute_location(grid_program, index, name)
gl.glLinkProgram(grid_program)
gl.glGetProgramiv(grid_program, 0x8B82, C.byref(linked))
assert linked.value, "production grid shader did not link"
gl.glUseProgram(grid_program)
gl.glUniformMatrix4fv(uniform_location(grid_program, b"CC_MVPMatrix"), 1, 0, matrix)
gl.glUniform1i(uniform_location(grid_program, b"CC_Texture0"), 0)
# Use the actual authored PNG bytes, including RGB in fully transparent
# interiors. The former test pre-multiplied them itself, hiding the Linux bug.
grid_image = Image.open(root / 'bin/res/assets/Images/UI/Adventure/SeaChart/Tiles/grid.png').convert('RGBA')
interior, line = grid_image.getpixel((1, 1)), grid_image.getpixel((0, 0))
assert interior == (225,251,243,0) and line == (225,251,243,75)
raw_grid = [interior, line, interior, line]

def draw_grid(samples):
    data = (C.c_ubyte * 16)(*(component for pixel in samples for component in pixel))
    gl.glTexImage2D(0x0DE1, 0, 0x1908, 2, 2, 0, 0x1908, 0x1401, data)
    gl.glClear(0x4000)
    gl.glDrawArrays(4, 0, 6)
    gl.glReadPixels(0, 0, 2, 2, 0x1908, 0x1401, result)
    actual = [tuple(result[i:i+4]) for i in range(0,16,4)]
    for got,wanted in zip(actual,[(20,80,130,255),(29,83,127,255)]*2):
        assert all(abs(a-b)<=1 for a,b in zip(got,wanted)), (actual,wanted)
    return actual

straight_grid_result = draw_grid(raw_grid)
# Some platforms supply already-premultiplied PNG texels. Production selects
# this exact define using Texture2D.hasPremultipliedAlpha, including restoration.
premul_frag = compile_stage(0x8B30, '#define GRID_TEXTURE_PREMULTIPLIED\n' + grid_fragment)
premul_program = gl.glCreateProgram()
attach(premul_program,vert);attach(premul_program,premul_frag)
for index,name in enumerate([b'a_position',b'a_color',b'a_texCoord']):
    attribute_location(premul_program,index,name)
gl.glLinkProgram(premul_program)
gl.glGetProgramiv(premul_program,0x8B82,C.byref(linked));assert linked.value
gl.glUseProgram(premul_program)
gl.glUniformMatrix4fv(uniform_location(premul_program,b'CC_MVPMatrix'),1,0,matrix)
gl.glUniform1i(uniform_location(premul_program,b'CC_Texture0'),0)
premul_grid_result = draw_grid([tuple(round(c*p[3]/255) for c in p[:3])+(p[3],) for p in raw_grid])
assert max(abs(a-b) for p,q in zip(straight_grid_result,premul_grid_result) for a,b in zip(p,q))<=1
# The accepted Linux material previously used this exact shader with the
# texture's default GL_SRC_ALPHA blend. Preserve its RGB contrast, while the
# corrected output also keeps an opaque destination's alpha opaque.
legacy_fragment = """
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D CC_Texture0;
void main() { gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord) * 0.42; }
"""
legacy_program = gl.glCreateProgram()
attach(legacy_program,vert);attach(legacy_program,compile_stage(0x8B30,legacy_fragment))
for index,name in enumerate([b'a_position',b'a_color',b'a_texCoord']):attribute_location(legacy_program,index,name)
gl.glLinkProgram(legacy_program);gl.glGetProgramiv(legacy_program,0x8B82,C.byref(linked));assert linked.value
gl.glUseProgram(legacy_program)
gl.glUniformMatrix4fv(uniform_location(legacy_program,b'CC_MVPMatrix'),1,0,matrix)
gl.glUniform1i(uniform_location(legacy_program,b'CC_Texture0'),0)
legacy_data=(C.c_ubyte*16)(*(c for p in raw_grid for c in p))
gl.glTexImage2D(0x0DE1,0,0x1908,2,2,0,0x1908,0x1401,legacy_data)
gl.glBlendFunc(770,771);gl.glClear(0x4000);gl.glDrawArrays(4,0,6)
gl.glReadPixels(0,0,2,2,0x1908,0x1401,result)
legacy_result=[tuple(result[i:i+4]) for i in range(0,16,4)]
assert max(abs(a-b) for p,q in zip(straight_grid_result,legacy_result) for a,b in zip(p[:3],q[:3]))<=1
# The opacity preservation must hold across both sea and pale-island backdrops.
for background in ((2,155,177),(230,211,155),(45,107,72)):
    gl.glClearColor(*(v/255 for v in background),1)
    for active_program,blend in ((grid_program,1),(legacy_program,770)):
        gl.glUseProgram(active_program);gl.glBlendFunc(blend,771);gl.glClear(0x4000);gl.glDrawArrays(4,0,6)
        gl.glReadPixels(0,0,2,2,0x1908,0x1401,result)
        values=[tuple(result[i:i+4]) for i in range(0,16,4)]
        if active_program==grid_program: corrected=values
        else: assert max(abs(a-b) for p,q in zip(corrected,values) for a,b in zip(p[:3],q[:3]))<=1
    assert corrected[0][:3]==background and corrected[2][:3]==background
# Restore the shared setup for the independent stencil test below.
gl.glClearColor(20/255,80/255,130/255,1);gl.glBlendFunc(1,771)
print('PASS actual grid PNG: clear interiors preserve sea/island RGB exactly, corrected lines match accepted old shader/default-blend contrast within one byte, both alpha upload formats agree')

# Exercise the same fixed-function alpha/stencil contract used by the shipped
# desktop ClippingNode. Only an independent source-alpha mask admits the child.
bind(gl, "glClearStencil", None, C.c_int)(0)
gl.glClear(0x4000 | 0x0400)
gl.glUseProgram(program)
gl.glTexImage2D(0x0DE1, 0, 0x1908, 2, 2, 0, 0x1908, 0x1401, pixels)
gl.glEnable(0x0B90)  # GL_STENCIL_TEST
bind(gl, "glStencilMask", None, C.c_uint)(255)
bind(gl, "glStencilFunc", None, C.c_uint, C.c_int, C.c_uint)(0x0207, 1, 255)
bind(gl, "glStencilOp", None, C.c_uint, C.c_uint, C.c_uint)(0x1E00, 0x1E00, 0x1E01)
bind(gl, "glColorMask", None, C.c_ubyte, C.c_ubyte, C.c_ubyte, C.c_ubyte)(0, 0, 0, 0)
gl.glEnable(0x0BC0)  # GL_ALPHA_TEST
bind(gl, "glAlphaFunc", None, C.c_uint, C.c_float)(0x0204, .5)
gl.glDrawArrays(4, 0, 6)
gl.glColorMask(1, 1, 1, 1)
bind(gl, "glDisable", None, C.c_uint)(0x0BC0)
gl.glStencilFunc(0x0202, 1, 255)
gl.glStencilOp(0x1E00, 0x1E00, 0x1E00)
opaque = (C.c_ubyte * 16)(*([0, 0, 0, 255] * 4))
gl.glTexImage2D(0x0DE1, 0, 0x1908, 2, 2, 0, 0x1908, 0x1401, opaque)
gl.glDrawArrays(4, 0, 6)
gl.glReadPixels(0, 0, 2, 2, 0x1908, 0x1401, result)
expected = [20, 80, 130, 255] * 2 + [3, 35, 52, 255] * 2
assert all(abs(got-wanted) <= 1 for got, wanted in zip(result, expected)), list(result)
print("PASS independent terrain alpha stencil on surfaceless GL: opaque child stays strictly inside original mask")
