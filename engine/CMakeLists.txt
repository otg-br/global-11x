cmake_minimum_required(VERSION 2.8)

set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

project(tfs)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(cotire)

add_compile_options(-Wall -Werror -pipe -fvisibility=hidden)

# Enable stats system
add_definitions(-DSTATS_ENABLED)

set(CMAKE_CXX_FLAGS_PERFORMANCE "${CMAKE_CXX_FLAGS_RELEASE} -Ofast -march=native -mtune=native -DBOOST_DISABLE_ASSERTS -DNDEBUG -g")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-Ofast -march=native -mtune=native -DBOOST_DISABLE_ASSERTS -DNDEBUG -g")

if (CMAKE_COMPILER_IS_GNUCXX)
    add_compile_options(-fno-strict-aliasing)
endif()

# Add UTF-8 support for MSVC
if(MSVC)
    add_compile_options(/utf-8)
    # Add Boost compatibility definitions for MSVC
    add_definitions(-DBOOST_CONFIG_SUPPRESS_DEPRECATED)
    add_definitions(-DBOOST_PREDEF_DISABLED)
endif()

include(FindCXX11)
include(FindLTO)

# Find packages.
find_package(Crypto++ REQUIRED)
find_package(PugiXML REQUIRED)
find_package(MySQL REQUIRED)
find_package(Threads)
find_package(fmt REQUIRED)

set (protoc_cmd "${PROJECT_SOURCE_DIR}/proto/generate.sh")
 
execute_process(COMMAND ${protoc_cmd}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/proto)

# Selects LuaJIT if user defines or auto-detected
if(DEFINED USE_LUAJIT AND NOT USE_LUAJIT)
    set(FORCE_LUAJIT ${USE_LUAJIT})
else()
    find_package(LuaJIT)
    set(FORCE_LUAJIT ${LuaJIT_FOUND})
endif()
option(USE_LUAJIT "Use LuaJIT" ${FORCE_LUAJIT})

if(FORCE_LUAJIT)
    if(APPLE)
      set(CMAKE_EXE_LINKER_FLAGS "-pagezero_size 10000 -image_base 100000000")
    endif()
else()
    find_package(Lua REQUIRED)
endif()

find_package(Boost 1.53.0 COMPONENTS system filesystem iostreams REQUIRED)

add_subdirectory(src)
add_executable(tfs ${tfs_SRC})

include_directories(${MYSQL_INCLUDE_DIR} ${LUA_INCLUDE_DIR} ${Boost_INCLUDE_DIRS} ${PUGIXML_INCLUDE_DIR} ${Crypto++_INCLUDE_DIR} ${fmt_INCLUDE_DIRS})
target_link_libraries(tfs ${MYSQL_CLIENT_LIBS} ${LUA_LIBRARIES} ${Boost_LIBRARIES} ${Boost_FILESYSTEM_LIBRARY} ${PUGIXML_LIBRARIES} ${Crypto++_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT} fmt::fmt)

# Precompiled header
# Note: cotire() must be called last on a target
if (${CMAKE_VERSION} VERSION_GREATER "3.16.0")
    target_precompile_headers(tfs PUBLIC src/otpch.h)
else ()
    include(cotire)
    set_target_properties(tfs PROPERTIES COTIRE_CXX_PREFIX_HEADER_INIT "src/otpch.h")
    set_target_properties(tfs PROPERTIES COTIRE_ADD_UNITY_BUILD FALSE)
    cotire(tfs)
endif ()

# Option to disable unity builds
option(ENABLE_UNITY_BUILD "Enable unity build" ON)

if(ENABLE_UNITY_BUILD)
    set_target_properties(tfs PROPERTIES UNITY_BUILD ON)
endif()
