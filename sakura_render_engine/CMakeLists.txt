cmake_minimum_required(VERSION 3.22 FATAL_ERROR)
set(PROJECT_NAME "sandbox") 

project(${PROJECT_NAME} LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 20)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Prior adding the package one can disable certain libraries
option(NVPRO2_ENABLE_nvgl OFF)
option(NVPRO2_ENABLE_nvgpu_monitor OFF)


# Add the cmake folder to the module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
find_package(NvproCore2 REQUIRED)


# Include the RtTutorial common functions
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/SetupFunction.cmake")


set(ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(COMMON_DIR "${CMAKE_CURRENT_SOURCE_DIR}/common")

# Path Variable
set(SAKURA_PATH  ${CMAKE_CURRENT_SOURCE_DIR}/sakura)
set(SANDBOX_PATH ${CMAKE_CURRENT_SOURCE_DIR}/sandbox)


#####################################################################################
# Add common library first as other samples might depend on it
add_subdirectory(common)

add_subdirectory(sakura/src)


file(GLOB SANDBOX_SOURCES
	"sandbox/src/*.cpp" 
	)

source_group("Sandbox" FILES ${SANDBOX_SOURCES})



#####################################################################################
# Executable
add_executable(${PROJECT_NAME} ${SANDBOX_SOURCES})

# Link libraries and include directories
target_link_libraries(${PROJECT_NAME} PRIVATE sakura)

# Include directory for generated files
target_include_directories(${PROJECT_NAME} PRIVATE 
    ${CMAKE_BINARY_DIR} 
    ${CMAKE_SOURCE_DIR} 
    ${ROOT_DIR}
)

# Define Marco that path_utils.hpp depend
target_compile_definitions(${PROJECT_NAME} PRIVATE
    TARGET_EXE_TO_ROOT_DIRECTORY="../../"                      # exe → root
    TARGET_EXE_TO_SOURCE_DIRECTORY="../../sakura/src/"         # exe → sakura source dir
    TARGET_EXE_TO_NVSHADERS_DIRECTORY="${NVSHADERS_DIR}"      # exe → NVSHADERS dir
    TARGET_NAME="${PROJECT_NAME}"                             # current executable program（sandbox）
    NVSHADERS_DIR="${NVSHADERS_DIR}"                          # NVSHADERS dir
)

# Make Visual Studio use this project as the startup project
set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})


# Install the resources and nvshaders folders
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/resources" DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/common/shaders" DESTINATION ${CMAKE_INSTALL_PREFIX}/common)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/common/io_gltf.h" DESTINATION ${CMAKE_INSTALL_PREFIX}/common)
install(DIRECTORY "${NVSHADERS_DIR}/nvshaders" DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES ${Slang_GLSLANG} DESTINATION ${CMAKE_INSTALL_PREFIX})


# currently, wo don't need addtional files, but one might need to
# copy required dlls, additional commands etc. through this command
# copy_to_runtime_and_install(${PROJECT_NAME}
#     DIRECTORIES ${RESOURCES_DIR} "${COMMON_DIR}/shaders" "${NVSHADERS_DIR}/nvshaders"
#     FILES ${Slang_GLSLANG} ${NsightAftermath_DLLS}
#     AUTO
# )
