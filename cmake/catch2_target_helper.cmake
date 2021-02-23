#[[

Helper function to handle the 'Catch2' target creation and to avoid duplicated boilerplate code.

#]]
function(make_catch2_target_available)
    if(NOT TARGET Catch2::Catch2)
        set(${PROJECT_NAME}_catch2_source_dir ${PROJECT_SOURCE_DIR}/dependency/Catch2)

        # enforce that the submodule is initialized and always at the correct commit
        include(git/submodule_updater)
        update_git_submodule(${${PROJECT_NAME}_catch2_source_dir})

        if(NOT EXISTS "${${PROJECT_NAME}_catch2_source_dir}/CMakeLists.txt")
            message(FATAL_ERROR
                "Catch2 dependency not found! Please update submodules manually and try again.")
        endif()

        # unset module path to not pollute third party projects
        unset(CMAKE_MODULE_PATH)

        add_subdirectory(
            ${${PROJECT_NAME}_catch2_source_dir}
            ${PROJECT_BINARY_DIR}/dependency/Catch2
        )

        # configure Catch2 include dir property to silence compiler/analyzer warnings
        target_include_directories(Catch2
            SYSTEM INTERFACE
                ${${PROJECT_NAME}_catch2_source_dir}/single_include
        )
    endif()
endfunction()
