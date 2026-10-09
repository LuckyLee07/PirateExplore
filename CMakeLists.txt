cmake_minimum_required(VERSION 3.18)
project(PirateExplore LANGUAGES C CXX)
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
  message(FATAL_ERROR "This entry point builds the Linux native game.")
endif()
if(NOT CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$" OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
  message(FATAL_ERROR "Bundled Linux FMOD/WebSockets libraries require 64-bit x86 Linux.")
endif()
set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_compile_definitions(LINUX CC_ENABLE_CHIPMUNK_INTEGRATION=1 COCOS2D_DEBUG=1)
set(E ${CMAKE_CURRENT_SOURCE_DIR}/src/engine/cocos2d-x)
set(PLATFORM_FOLDER linux)
set(ARCH_DIR 64-bit)
include_directories(${E} ${E}/cocos ${E}/cocos/2d ${E}/cocos/2d/renderer
  ${E}/cocos/2d/platform ${E}/cocos/2d/platform/linux ${E}/cocos/2d/platform/desktop
  ${E}/extensions/GUI/CCScrollView ${E}/extensions/GUI/CCControlExtension
  ${E}/cocos/base ${E}/cocos/deprecated ${E}/cocos/physics ${E}/cocos/editor-support
  ${E}/cocos/math/kazmath ${E}/cocos/audio/include ${E}/extensions ${E}/external
  ${E}/external/tinyxml2 ${E}/external/unzip ${E}/external/edtaa3func ${E}/external/xxhash
  ${E}/external/chipmunk/include/chipmunk ${E}/external/lua/lua ${E}/external/lua/tolua
  ${E}/external/lua/luasocket ${E}/cocos/scripting/lua-bindings/auto
  ${E}/cocos/scripting/lua-bindings/manual ${E}/external/websockets/include/linux)
find_path(GLFW_INCLUDE_DIR glfw3.h PATH_SUFFIXES GLFW REQUIRED)
include_directories(${GLFW_INCLUDE_DIR})
find_package(Freetype REQUIRED)
include_directories(${FREETYPE_INCLUDE_DIRS})
link_directories(${E}/external/linux-specific/fmod/prebuilt/64-bit
  ${E}/external/websockets/prebuilt/linux/64-bit)
set(chipmunk_SOURCE_DIR ${E}/external/chipmunk)
foreach(component cocos/math/kazmath external/chipmunk/src external/unzip external/tinyxml2
    external/xxhash cocos/audio cocos/base cocos/2d cocos/storage cocos/ui cocos/network
    extensions cocos/editor-support/spine cocos/editor-support/cocosbuilder
    cocos/editor-support/cocostudio external/lua/lua external/lua/tolua cocos/scripting/lua-bindings)
  add_subdirectory(${E}/${component} ${CMAKE_BINARY_DIR}/engine/${component})
endforeach()
target_sources(cocos2d PRIVATE ${E}/cocos/2d/CSVParse.cpp ${E}/cocos/2d/ZQCSVParse.cpp)
find_path(WEBP_INCLUDE_DIR decode.h PATH_SUFFIXES webp REQUIRED)
target_include_directories(cocos2d PRIVATE ${WEBP_INCLUDE_DIR})
file(GLOB SOCKET_SRC ${E}/external/lua/luasocket/*.c)
list(FILTER SOCKET_SRC EXCLUDE REGEX "/wsocket.c$")
add_library(luasocket STATIC ${SOCKET_SRC})
target_include_directories(luasocket PRIVATE ${E}/external/lua/lua)
file(GLOB APP_SRC src/NewPirate/common/UtilTools/*.cpp src/NewPirate/game/ToLua/*.cpp)
add_executable(PirateExplore projects/linux/main.cpp src/NewPirate/client/AppDelegate.cpp ${APP_SRC})
target_include_directories(PirateExplore PRIVATE src/NewPirate/client src/NewPirate/common src/NewPirate/common/UtilTools src/NewPirate/game)
target_link_libraries(PirateExplore PRIVATE -Wl,--start-group luabinding extensions cocostudio cocosbuilder
  ui network storage audio spine cocos2d cocosbase tolua lua luasocket -Wl,--end-group dl m)
set_target_properties(PirateExplore PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
add_custom_command(TARGET PirateExplore POST_BUILD COMMAND ${CMAKE_COMMAND} -E create_symlink
  ${CMAKE_CURRENT_SOURCE_DIR}/bin/res $<TARGET_FILE_DIR:PirateExplore>/Resources)

add_custom_command(TARGET PirateExplore POST_BUILD COMMAND ${CMAKE_COMMAND} -E create_symlink
  ${E}/cocos/scripting/lua-bindings/script $<TARGET_FILE_DIR:PirateExplore>/engine-scripts)
