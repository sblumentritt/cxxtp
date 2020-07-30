target_sources(${${PROJECT_NAME}_target}
    PRIVATE
        # add private source files here
)

target_include_directories(${${PROJECT_NAME}_target}
    PRIVATE
        ${CMAKE_CURRENT_LIST_DIR}
)
