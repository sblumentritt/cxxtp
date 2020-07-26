target_sources(${${PROJECT_NAME}_target}
    PRIVATE
        main.cpp
)

target_include_directories(${${PROJECT_NAME}_target}
    PRIVATE
        ${CMAKE_CURRENT_LIST_DIR}
)
