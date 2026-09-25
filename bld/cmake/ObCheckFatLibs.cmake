#.rst:
# This file provides the function:
#  ObCheckFatLibs - warn about non-universal libraries on macOS
#
# Copyright (C) 2026 ANIMIST contributors

# ObCheckFatLibs
# ---------------
#
# Syntax:
# ObCheckFatLibs(libname...)
#
# When building a universal binary (i.e. CMAKE_OSX_ARCHITECTURES names
# more than one architecture), check that each named library actually
# contains all of the requested architectures, and warn if it does not.
#
# Our library detection elsewhere only checks that a library (or its
# header) is present, not what architectures it was built for.  Without
# this warning, a thin dependency configures cleanly and then fails at
# link time with a rather cryptic complaint about "building for
# macOS-arm64 but linking file built for macOS-x86_64".
#
# This function only ever warns; it never fails the configure step.

FUNCTION(ObCheckFatLibs)
    IF (NOT APPLE)
        RETURN()
    ENDIF()

    LIST(LENGTH CMAKE_OSX_ARCHITECTURES _narch)
    IF (_narch LESS 2)
        # Not a universal build; nothing to check.
        RETURN()
    ENDIF()

    FIND_PROGRAM(LIPO_EXECUTABLE lipo)
    IF (NOT LIPO_EXECUTABLE)
        MESSAGE(STATUS "lipo not found; skipping universal library check")
        RETURN()
    ENDIF()

    FOREACH (name ${ARGN})
        FIND_LIBRARY(_fatchk_path NAMES ${name})
        IF (_fatchk_path)
            EXECUTE_PROCESS(
                COMMAND ${LIPO_EXECUTABLE} -archs ${_fatchk_path}
                OUTPUT_VARIABLE _archs
                ERROR_QUIET
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )
            FOREACH (arch ${CMAKE_OSX_ARCHITECTURES})
                IF (NOT _archs MATCHES "(^| )${arch}( |$)")
                    MESSAGE(WARNING
                        "${_fatchk_path} has no ${arch} slice "
                        "(it has: ${_archs}).  Linking will probably "
                        "fail.  You will need a universal build of "
                        "lib${name}.")
                ENDIF()
            ENDFOREACH()
        ENDIF()
        # Don't leave the probe's result cached, since we only wanted
        # it for the check.
        UNSET(_fatchk_path CACHE)
    ENDFOREACH()
ENDFUNCTION()
