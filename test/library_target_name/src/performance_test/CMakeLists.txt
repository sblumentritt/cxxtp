# define/configure the target
# -------------------------------------
add_executable(${${PROJECT_NAME}_target_performance_test} EXCLUDE_FROM_ALL)
add_executable(
    test::${${PROJECT_NAME}_target_performance_test}
    ALIAS
    ${${PROJECT_NAME}_target_performance_test}
)

# use helper function to configure a target
configure_target(
    TARGET
        ${${PROJECT_NAME}_target_performance_test}
    CXX_STANDARD
        ##TEMPLATE_CXX_STANDARD#
    COMPILER_FLAGS
        "${${PROJECT_NAME}_cxx_compiler_flags}"
    SANITIZER_FLAGS
        "${${PROJECT_NAME}_sanitizer_flags}"
    LINKER_FLAGS
        "${${PROJECT_NAME}_linker_flags}"
    PRIVATE_DEFINITION_FLAGS
        CATCH_CONFIG_ENABLE_BENCHMARKING=1
    PRIVATE_INCLUDE_DIRS
        ${CMAKE_CURRENT_LIST_DIR}
        ${PROJECT_BINARY_DIR}
    BUILD_TYPE_AS_OUTPUT_DIR
    ENABLE_UNUSED_SECTION_GARBAGE_COLLECTION
)

# add analyzer to target
include(analyzer/clang_tidy)
register_for_clang_tidy(${${PROJECT_NAME}_target_performance_test})

include(analyzer/cppcheck)
register_for_cppcheck(${${PROJECT_NAME}_target_performance_test})

# strip binary for specific build types
include(utility/postbuild_strip_command)
add_postbuild_strip(${${PROJECT_NAME}_target_performance_test})

# add source files and include sub-folder
# -------------------------------------
target_sources(${${PROJECT_NAME}_target_performance_test}
    PRIVATE
        main_perf.cpp
)

# link against dependencies
# -------------------------------------
# link against the library which contains the whole logic
target_link_libraries(${${PROJECT_NAME}_target_performance_test}
    PRIVATE
        ${${PROJECT_NAME}_target_##LIBRARY_TARGET_NAME##}::${${PROJECT_NAME}_target_##LIBRARY_TARGET_NAME##}
)

include(catch2_target_helper)
make_catch2_target_available()

target_link_libraries(${${PROJECT_NAME}_target_performance_test}
    PRIVATE
        Catch2::Catch2
)
