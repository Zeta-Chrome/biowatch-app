cmake_minimum_required(VERSION 3.21)
project(BWApp VERSION 1.0.0 LANGUAGES CXX)

set(EXECUTABLE_NAME "bwapp")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(QT_QML_GENERATE_QMLLS_INI ON)
set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS 1 CACHE BOOL "" FORCE)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# Output directories
if (ANDROID)
    set(PLATFORM_NAME "android")
    set(ARCH_NAME "arm64_v8a")
else() 
    set(PLATFORM_NAME "linux")
    set(ARCH_NAME "x86_64")
endif()

set(QT_DIR "$ENV{QT_BASE}/$ENV{ABI}")
list(APPEND CMAKE_PREFIX_PATH "${QT_DIR}/lib/cmake")
list(APPEND CMAKE_FIND_ROOT_PATH "${QT_DIR}")

find_package(Qt6Core)
find_package(Qt6Gui)
find_package(Qt6Qml)
find_package(Qt6Quick)
find_package(Qt6Multimedia)
find_package(Qt6Concurrent)

# Recursively find all source files
file(GLOB_RECURSE SOURCES
    ${CMAKE_SOURCE_DIR}/src/*.cpp
)

# Recursively find all header files
file(GLOB_RECURSE HEADERS
    ${CMAKE_SOURCE_DIR}/include/biowatch_app/*.h
)

# Recursively find all QML files
file(GLOB_RECURSE QML_FILES RELATIVE ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/ui/*.qml
)

# Recursively find all image assets
file(GLOB_RECURSE IMAGE_ASSETS RELATIVE ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/assets/images/*.svg
)

# Create executable and QML module together
qt_add_executable(${EXECUTABLE_NAME} ${SOURCES} ${HEADERS})

target_include_directories(${EXECUTABLE_NAME} PUBLIC
    ${CMAKE_SOURCE_DIR}/include/biowatch_app
)

set_source_files_properties(ui/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt6_add_qml_module(${EXECUTABLE_NAME}
    URI "BWApp"
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES ${QML_FILES}
    SOURCES ${SOURCES} ${HEADERS}
    RESOURCES ${IMAGE_ASSETS}
)

# Link Qt libraries
target_link_libraries(${EXECUTABLE_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Multimedia
    Qt6::Concurrent
)

# Android specific configuration
if(ANDROID)
    set_target_properties(${EXECUTABLE_NAME} PROPERTIES
        QT_ANDROID_APP_NAME "BWApp"
        QT_ANDROID_APP_ICON "@mipmap/ic_launcher"
        QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_SOURCE_DIR}/android
    )
    
    install(TARGETS ${EXECUTABLE_NAME}
        BUNDLE DESTINATION .
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
    )
endif()
