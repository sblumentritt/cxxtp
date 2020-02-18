# Provides functions to check supported compiler flags.
#
# The following functions will be provided:
#     check_supported_cxx_compiler_flags - check if given compiler flags are supported
#     check_supported_c_compiler_flags - check if given compiler flags are supported

include_guard(GLOBAL)

#[[

Check if the given compiler flags are supported by the current compiler.

check_supported_cxx_compiler_flags(<compiler-flags> <supported-compiler-flags>)

- <compiler-flags>
List of compiler flags which should be checked.

- <supported-compiler-flags>
Stores the resulting supported compiler flags as list in the given variable.
The content of the given variable will be completely overridden.

The following cache variables will be set/provided:
    <project-name>_cache_cxx_compiler_flags - True if C++ compiler flags should be cached.

#]]
function(check_supported_cxx_compiler_flags compiler_flags supported_compiler_flags)
    # define cache variable
    set(${PROJECT_NAME}_cache_cxx_compiler_flags OFF
        CACHE
            BOOL "Cache C++ compiler flags to speed up cmake reconfiguration"
    )

    if(${PROJECT_NAME}_cache_cxx_compiler_flags AND ${PROJECT_NAME}_cached_cxx_compiler_flags)
        # safe result in the given output variable
        set(${supported_compiler_flags}
            ${${PROJECT_NAME}_cached_cxx_compiler_flags}
            PARENT_SCOPE
        )
    else()
        # get the helper function from cmake
        include(CheckCXXCompilerFlag)

        foreach(flag IN LISTS compiler_flags)
            # create variable used for cmake cache entry
            string(TOUPPER ${flag} cache_entry_flag_name)

            if((CMAKE_C_COMPILER_ID MATCHES GNU) OR (CMAKE_C_COMPILER_ID MATCHES Clang))
                string(
                    REGEX REPLACE
                        "^-W|^-" "CXX_FLAG_"
                    cache_entry_flag_name
                    ${cache_entry_flag_name}
                )

                string(
                    REGEX REPLACE
                        "[-=]" "_"
                    cache_entry_flag_name
                    ${cache_entry_flag_name}
                )
            elseif(CMAKE_C_COMPILER_ID MATCHES MSVC)
                string(
                    REGEX REPLACE
                        "^-/|^-" "CXX_FLAG_"
                    cache_entry_flag_name
                    ${cache_entry_flag_name}
                )
            endif()

            # call module function which does the actual check
            check_cxx_compiler_flag(${flag} ${cache_entry_flag_name})

            # NOTE: positive result indicates only that the compiler
            #       did not issue a diagnostic message with the flag
            if(${cache_entry_flag_name})
                list(APPEND internal_supported_flags ${flag})
            endif()

            # unset cache to always check on cmake run
            unset(${cache_entry_flag_name} CACHE)
        endforeach()

        if(${PROJECT_NAME}_cache_cxx_compiler_flags)
            set(
                ${PROJECT_NAME}_cached_cxx_compiler_flags
                    "${internal_supported_flags}"
                CACHE
                    INTERNAL ""
            )
        elseif(${PROJECT_NAME}_cached_cxx_compiler_flags)
            unset(${PROJECT_NAME}_cached_cxx_compiler_flags CACHE)
        endif()

        # safe result in the given output variable
        set(${supported_compiler_flags} ${internal_supported_flags} PARENT_SCOPE)
    endif()
endfunction()

#[[

Check if the given compiler flags are supported by the current compiler.

check_supported_c_compiler_flags(<compiler-flags> <supported-compiler-flags>)

- <compiler-flags>
List of compiler flags which should be checked.

- <supported-compiler-flags>
Stores the resulting supported compiler flags as list in the given variable.
The content of the given variable will be completely overridden.

The following cache variables will be set/provided:
    <project-name>_cache_c_compiler_flags - True if C compiler flags should be cached.

#]]
function(check_supported_c_compiler_flags compiler_flags supported_compiler_flags)
    # define cache variable
    set(${PROJECT_NAME}_cache_c_compiler_flags OFF
        CACHE
            BOOL "Cache C compiler flags to speed up cmake reconfiguration"
    )

    if(${PROJECT_NAME}_cache_c_compiler_flags AND ${PROJECT_NAME}_cached_c_compiler_flags)
        # safe result in the given output variable
        set(
            ${supported_compiler_flags}
            ${${PROJECT_NAME}_cached_c_compiler_flags}
            PARENT_SCOPE
        )
    else()
        # get the helper function from cmake
        include(CheckCCompilerFlag)

        foreach(flag IN LISTS compiler_flags)
            # create variable used for cmake cache entry
            string(TOUPPER ${flag} cache_entry_flag_name)

            if((CMAKE_C_COMPILER_ID MATCHES GNU) OR (CMAKE_C_COMPILER_ID MATCHES Clang))
                string(
                    REGEX REPLACE
                        "^-W|^-" "C_FLAG_"
                    cache_entry_flag_name
                    ${cache_entry_flag_name}
                )

                string(
                    REGEX REPLACE
                        "[-=]" "_"
                    cache_entry_flag_name
                    ${cache_entry_flag_name}
                )
            elseif(CMAKE_C_COMPILER_ID MATCHES MSVC)
                string(
                    REGEX REPLACE
                        "^-/|^-" "C_FLAG_"
                    cache_entry_flag_name
                    ${cache_entry_flag_name}
                )
            endif()

            # call module function which does the actual check
            check_c_compiler_flag(${flag} ${cache_entry_flag_name})

            # NOTE: positive result indicates only that the compiler
            #       did not issue a diagnostic message with the flag
            if(${cache_entry_flag_name})
                list(APPEND internal_supported_flags ${flag})
            endif()

            # unset cache to always check on cmake run
            unset(${cache_entry_flag_name} CACHE)
        endforeach()

        if(${PROJECT_NAME}_cache_c_compiler_flags)
            set(
                ${PROJECT_NAME}_cached_c_compiler_flags
                    "${internal_supported_flags}"
                CACHE
                    INTERNAL ""
            )
        elseif(${PROJECT_NAME}_cached_c_compiler_flags)
            unset(${PROJECT_NAME}_cached_c_compiler_flags CACHE)
        endif()

        # safe result in the given output variable
        set(${supported_compiler_flags} ${internal_supported_flags} PARENT_SCOPE)
    endif()
endfunction()
