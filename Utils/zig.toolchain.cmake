if(DEFINED ENV{TARGET_SYS})
  set(TARGET_SYS $ENV{TARGET_SYS})
endif()

if(TARGET_SYS AND NOT ZIG_INIT)
  set(ZIG_INIT ON)
  set(ZIG_HACK)
  set(LLVM_VERSION 17)
  if(DEFINED ENV{ZIG_TOOLCHAIN_PATH})
    set(ZIG_TOOLCHAIN_PATH $ENV{ZIG_TOOLCHAIN_PATH})
  endif()
  if(NOT ZIG_TOOLCHAIN_PATH)
    find_program(ZIG_TOOLCHAIN_PATH NAMES zig REQUIRED)
  endif()

  #https://github.com/ziglang/zig/wiki/FAQ#why-do-i-get-illegal-instruction-when-using-with-zig-cc-to-build-c-code
  set(BUILDFLAGS "-fno-sanitize=undefined -fno-sanitize-trap=undefined")

  if(${TARGET_SYS} STREQUAL native)
    set(CMAKE_SIZEOF_VOID_P 8)
    set(CMAKE_SIZEOF_UNSIGNED_SHORT 2)
  else()
    string(REPLACE "-" ";" TARGETS ${TARGET_SYS})

    list(GET TARGETS 0 ARCH)
    list(GET TARGETS 1 TARGET)
    list(GET TARGETS 2 LIBC)

    string(SUBSTRING ${TARGET} 0 1 T1)
    string(TOUPPER ${T1} T1)
    string(SUBSTRING ${TARGET} 1 10 TARGET)
    set(TARGET "${T1}${TARGET}")

    if(${TARGET} STREQUAL Macos)
      set(TARGET Darwin)
      set(HAVE_FLAG_SEARCH_PATHS_FIRST 0)
      set(CMAKE_OSX_SYSROOT "")  #not use SYSROOT
      set(APPLE 1)
      set(UNIX 1)
      set(CMAKE_OSX_DEPLOYMENT_TARGET "10.09")
    endif()
    if(${TARGET} STREQUAL Linux)
      set(UNIX 1)
    endif()
    if(${TARGET} STREQUAL Windows)
      set(CMAKE_C_LINK_LIBRARY_SUFFIX "")
      set(WIN32 1)
      if (${ARCH} STREQUAL x86)
        set(ZIG_HACK "--fno-lto")
      endif()
    endif()

    string(FIND ${ARCH} "64" BIT64)
    if(NOT ${BIT64} EQUAL -1)
      set(CMAKE_SIZEOF_VOID_P 8)
    else()
      set(CMAKE_SIZEOF_VOID_P 4)
    endif()
    set(CMAKE_SIZEOF_UNSIGNED_SHORT 2)
    set(CMAKE_CROSSCOMPILING ON)
    set(CMAKE_SYSTEM_NAME ${TARGET})
    set(CMAKE_SYSTEM_PROCESSOR ${ARCH})
  endif()

  include(CMakeForceCompiler)

  set(CMAKE_C_COMPILER_FORCED 1)
  set(CMAKE_C_COMPILER_ID_RUN TRUE)
  set(CMAKE_C_COMPILER ${ZIG_TOOLCHAIN_PATH} cc "--target=${TARGET_SYS}")
  set(CMAKE_C_COMPILER_ID "zig")
  set(CMAKE_C_COMPILER_VERSION ${LLVM_VERSION})
  set(CMAKE_C_COMPILER_TARGET   ${TARGET_SYS})
  set(CMAKE_C_FLAGS_INIT "${BUILDFLAGS} ${ISYSTEM} ${ZIG_HACK}")

  set(CMAKE_ASM_COMPILER_FORCED 1)
  set(CMAKE_ASM_COMPILER_ID_RUN TRUE)
  set(CMAKE_ASM_COMPILER ${ZIG_TOOLCHAIN_PATH} cc "--target=${TARGET_SYS}")
  set(CMAKE_ASM_COMPILER_ID "zig")
  set(CMAKE_ASM_COMPILER_VERSION ${LLVM_VERSION})
  set(CMAKE_ASM_COMPILER_TARGET   ${TARGET_SYS})
  set(CMAKE_ASM_FLAGS_INIT "${BUILDFLAGS}  ${ISYSTEM} ${ZIG_HACK}")

  set(CMAKE_CXX_COMPILER_FORCED 1)
  set(CMAKE_CXX_COMPILER_ID_RUN TRUE)
  set(CMAKE_CXX_COMPILER ${ZIG_TOOLCHAIN_PATH} c++ "--target=${TARGET_SYS}")
  set(CMAKE_CXX_COMPILER_ID "zig")
  set(CMAKE_CXX_COMPILER_VERSION ${LLVM_VERSION})
  set(CMAKE_CXX_COMPILER_TARGET   ${TARGET_SYS})
  set(CMAKE_CXX_FLAGS_INIT "${BUILDFLAGS} ${ISYSTEM} ${ZIG_HACK}")

  SET(CMAKE_AR ${ZIG_TOOLCHAIN_PATH})
  SET(CMAKE_RANLIB ${ZIG_TOOLCHAIN_PATH})

  set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> ar qc <TARGET> <LINK_FLAGS> <OBJECTS>")
  SET(CMAKE_C_ARCHIVE_FINISH "<CMAKE_RANLIB> ranlib <TARGET>")
  set(CMAKE_C_ARCHIVE_APPEND "<CMAKE_AR> ar q <TARGET> <LINK_FLAGS> <OBJECTS>")

  SET(CMAKE_ASM_ARCHIVE_CREATE ${CMAKE_C_ARCHIVE_CREATE})
  SET(CMAKE_ASM_ARCHIVE_FINISH ${CMAKE_C_ARCHIVE_FINISH})
  SET(CMAKE_ASM_ARCHIVE_APPEND ${CMAKE_C_ARCHIVE_APPEND})

  SET(CMAKE_CXX_ARCHIVE_CREATE ${CMAKE_C_ARCHIVE_CREATE})
  SET(CMAKE_CXX_ARCHIVE_FINISH ${CMAKE_C_ARCHIVE_FINISH})
  SET(CMAKE_CXX_ARCHIVE_APPEND ${CMAKE_C_ARCHIVE_APPEND})

  message(STATUS "${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
endif()
