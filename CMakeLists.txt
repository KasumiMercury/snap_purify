cmake_minimum_required(VERSION 3.16)

project(snap_purify VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(appsnap_purify
    main.cpp
    imagemanager.h
    imagemanager.cpp
    imageprovider.h
    markermodel.h
    markermodel.cpp
)

qt_add_qml_module(appsnap_purify
    URI snap_purify
    QML_FILES
        Main.qml
        ImageCanvas.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appsnap_purify PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appsnap_purify
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appsnap_purify
    PRIVATE Qt6::Quick Qt6::QuickControls2
)

install(TARGETS appsnap_purify
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
