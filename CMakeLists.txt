cmake_minimum_required(VERSION 3.17.0 FATAL_ERROR)

# define top-level project
project("##TEMPLATE_PROJECT_NAME##"
    VERSION
        0.1.0
    DESCRIPTION
        "TODO: add a description for the project"
    LANGUAGES
        CXX
)

# generate a compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# unset module path to not get polluted from including projects
unset(CMAKE_MODULE_PATH)

# global variables
# -------------------------------------
##SECTION_EXECUTABLE_TYPE##set(${PROJECT_NAME}_target_##TEMPLATE_TARGET_NAME## "##TEMPLATE_TARGET_NAME##")
##SECTION_LIBRARY_TYPE##set(${PROJECT_NAME}_target_lib##TEMPLATE_TARGET_NAME## "lib##TEMPLATE_TARGET_NAME##")
# generic documentation target
set(${PROJECT_NAME}_target_documentation "documentation")

# append custom cmake paths to module search
# -------------------------------------
list(APPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_LIST_DIR}/dependency/cmake_modules"
)

# stop if system is not unix/linux
# -------------------------------------
if(NOT UNIX)
    message(FATAL_ERROR "Only UNIX systems are supported!")
endif()

include(utility/build_type_handler)
setup_build_type_variables()

include(generic_target/format)
define_format_targets()

# includes cmake files for meta information generation
# -------------------------------------
include(git/revision_description)
get_git_revision_description(${PROJECT_NAME}_current_git_revision)

include(info_provider/meta_information_generator)
generate_meta_information_header("${PROJECT_NAME}" "${${PROJECT_NAME}_current_git_revision}")

# define compiler/linker flags
# -------------------------------------
# get list of common compiler flags which should be used
include(compiler/common_compiler_flags)
get_common_cxx_compiler_flags(${PROJECT_NAME}_compiler_flags_to_test)

# check which flags are supported by the compiler
include(compiler/compiler_flag_check)
check_supported_cxx_compiler_flags(
    "${${PROJECT_NAME}_compiler_flags_to_test}"
    ${PROJECT_NAME}_cxx_compiler_flags
)

include(utility/sanitizer_flags)
get_sanitizer_flags(
    RESULT
        ${PROJECT_NAME}_sanitizer_flags
    ADDRESS
    UNDEFINED_BEHAVIOR
)

# check if a faster linker is available
include(utility/available_linker_check)
check_available_linker(${PROJECT_NAME}_linker_flags)

add_subdirectory(src)

# check if the calling project is the root project
if(PROJECT_NAME STREQUAL CMAKE_PROJECT_NAME)
    add_subdirectory(doc)
endif()
