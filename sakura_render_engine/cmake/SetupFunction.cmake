# Usage:
#   setup_function(
#     [USE_RT_COMMON]                    # Include sakura common sources (default: OFF)
#     [USE_FOUNDATION_SHADER]            # Include foundation.slang (default: OFF)
#     [EXTRA_SHADER_INCLUDES <dirs>]     # Additional shader include directories
#     [EXTRA_COPY_FILES <files>]         # Additional files to copy
#     [EXTRA_COPY_DIRECTORIES <dirs>]    # Additional directories to copy
#     [INCLUDE_H_SLANG_FILES]            # Include .h.slang files in shader compilation
#   )

function(setup_function)
    # Parse function arguments
    set(options USE_RT_COMMON USE_FOUNDATION_SHADER INCLUDE_H_SLANG_FILES)
    set(oneValueArgs)
    set(multiValueArgs EXTRA_SHADER_INCLUDES EXTRA_COPY_FILES EXTRA_COPY_DIRECTORIES)
    cmake_parse_arguments(SAKURA "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})


    # Variables
    set(SOURCE_PATH  ${CMAKE_CURRENT_LIST_DIR})
    set(AUTOGEN_PATH ${CMAKE_CURRENT_LIST_DIR}/_autogen)
    set(PROJECT_NAME "sakura") 
    set(LIB_TYPE "STATIC")

    # Check ROOT_DIR and COMMON_DIR
    if(NOT DEFINED ROOT_DIR)
        set(ROOT_DIR ${CMAKE_SOURCE_DIR}) 
    endif()
    if(NOT DEFINED COMMON_DIR)
        set(COMMON_DIR ${ROOT_DIR}/common) 
    endif()


    project(${PROJECT_NAME})
    message(STATUS "Processing library: ${PROJECT_NAME} (Type: ${LIB_TYPE})")

    # Adding all sources
    file(GLOB_RECURSE SAKURA_SOURCES 
    "*.h" 
    "*.c" 
    "*.cpp" 
    "*.hpp" 
    "*.md")
    source_group("Sakura" FILES ${SAKURA_SOURCES})

    # Handle common sources if requested
    set(ALL_SOURCES ${SAKURA_SOURCES})
    if(SAKURA_USE_RT_COMMON)
        # Define RT common directory
        set(RT_COMMON_DIR "${TUTO_DIR}/common")
        
        # Add common files to make them visible in Visual Studio
        file(GLOB RT_COMMON_SOURCES "${RT_COMMON_DIR}/*.cpp" "${RT_COMMON_DIR}/*.hpp")
        source_group("Sakura Common" FILES ${RT_COMMON_SOURCES})
        list(APPEND ALL_SOURCES ${RT_COMMON_SOURCES})
    endif()


    add_library(${PROJECT_NAME} ${LIB_TYPE} ${ALL_SOURCES})

    # dynamic lib must use SAKURA_DLL_EXPORT
    # target_compile_definitions(${PROJECT_NAME} PRIVATE SAKURA_DLL_EXPORT)
    # target_compile_definitions(${PROJECT_NAME} INTERFACE SAKURA_DLL_IMPORT)



    # Out put directory
    set_target_properties(${PROJECT_NAME} PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib" # static lib
        # LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib" # dynamic lib（Linux/macOS）
        # RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" # dynamic lib（Windows DLL） 
    )


    # Link libraries and include directories
    target_link_libraries(${PROJECT_NAME} PUBLIC
        nvpro2::nvapp
        nvpro2::nvgui
        nvpro2::nvslang
        nvpro2::nvutils
        nvpro2::nvvk
        nvpro2::nvshaders_host
        nvpro2::nvaftermath
        nvpro2::nvvkgltf
        nvpro2::nvvkglsl
        sakura_common
    )

    add_project_definitions(${PROJECT_NAME})

    # Include directory for generated files
    target_include_directories(${PROJECT_NAME} PUBLIC 
        ${CMAKE_BINARY_DIR} 
        ${CMAKE_SOURCE_DIR} 
        ${ROOT_DIR}
        ${SOURCE_PATH}
        ${AUTOGEN_PATH}
    )

    #------------------------------------------------------------------------------------------------------------------------------
    # Compile Shaders
    compile_shaders(
        PROJECT_NAME ${PROJECT_NAME}  
    )
    #------------------------------------------------------------------------------------------------------------------------------
    # Installation, copy files
    sakura_copy_resources(
        # 1. Optional：Only use when pass custom directory
        # SHADER_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/my_custom_shaders"  
        # DEST_ROOT_DIR "${CMAKE_BINARY_DIR}/my_custom_bin"                
        
        # 2. Must
        EXTRA_COPY_FILES     ${SAKURA_EXTRA_COPY_FILES}          
        EXTRA_COPY_DIRECTORIES ${SAKURA_EXTRA_COPY_DIRECTORIES}  
    )

endfunction()



# Usage:
#   compile_shaders(
#     [USE_FOUNDATION_SHADER]            
#     [PROJECT_NAME]                  
#     [AUTOGEN_DIRECTORIES <dirs>]    
#     [EXTRA_SHADER_INCLUDES <dirs>]     
#   )

function(compile_shaders)
    # Parse function arguments
    set(options 
        USE_FOUNDATION_SHADER
        INCLUDE_H_SLANG_FILES
    )
    set(oneValueArgs 
        PROJECT_NAME
        AUTOGEN_DIRECTORY 
        COMMON_DIR            
        NVSHADERS_DIR         
    )
    set(multiValueArgs
        EXTRA_SHADER_INCLUDES 
    )
    cmake_parse_arguments(SHADER "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})


    # Set default values
    if(NOT DEFINED SHADER_PROJECT_NAME)
        set(SHADER_PROJECT_NAME ${PROJECT_NAME})
        message(WARNING "compile_shaders: No assign PROJECT_NAME，ues ${SHADER_PROJECT_NAME} as default.")
    endif()

    if(NOT DEFINED SHADER_AUTOGEN_DIRECTORY)
        set(SHADER_AUTOGEN_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/_autogen")
    endif()

    if(NOT DEFINED SHADER_COMMON_DIR AND DEFINED ROOT_DIR)
        set(SHADER_COMMON_DIR "${ROOT_DIR}/common")
    endif()

    if(NOT DEFINED SHADER_NVSHADERS_DIR)
        if(DEFINED ENV{NVSHADERS_DIR})
            set(SHADER_NVSHADERS_DIR "$ENV{NVSHADERS_DIR}")
        elseif(DEFINED NVSHADERS_DIR)
            set(SHADER_NVSHADERS_DIR ${NVSHADERS_DIR})
        else()
            message(FATAL_ERROR "compile_shaders: No assign NVSHADERS_DIR，can't find stand shader（such as sky_simple.slang）")
        endif()
    endif()

    # Compile shaders
    set(SHADER_OUTPUT_DIR ${SHADER_AUTOGEN_DIRECTORY})
    file(GLOB SHADER_GLSL_FILES "shaders/*.glsl")
    file(GLOB SHADER_SLANG_FILES "shaders/*.slang")
    
    # Handle .h.slang files if requested
    if(SHADER_INCLUDE_H_SLANG_FILES)
        file(GLOB SHADER_H_FILES "shaders/*.h" "shaders/*.h.slang")
        list(FILTER SHADER_SLANG_FILES EXCLUDE REGEX ".*\\.h\\.slang$")
    else()
        file(GLOB SHADER_H_FILES "shaders/*.h")
    endif()

    # Adding standard shaders 
    # TODO : expose this
    list(APPEND SHADER_SLANG_FILES 
        ${SHADER_NVSHADERS_DIR}/nvshaders/sky_simple.slang
        ${SHADER_NVSHADERS_DIR}/nvshaders/tonemapper.slang
    )

    # Add foundation shader if requested
    if(SHADER_USE_FOUNDATION_SHADER)
        list(APPEND SHADER_SLANG_FILES 
            ${COMMON_DIR}/shaders/foundation.slang)
    endif()

    # Build shader include flags
    set(SHADER_INCLUDE_FLAGS 
        "-I${SHADER_NVSHADERS_DIR}" 
        "-I${ROOT_DIR}"
    )

    if(SHADER_EXTRA_SHADER_INCLUDES)
        foreach(include_dir ${SHADER_EXTRA_SHADER_INCLUDES})
            if(EXISTS ${include_dir})
                list(APPEND SHADER_INCLUDE_FLAGS "-I${include_dir}")
                message(STATUS "compile_shaders: new shader directory：${include_dir}")
            else()
                message(WARNING "compile_shaders: no such shader directory：${include_dir}")
            endif()
        endforeach()
    endif()

    compile_slang(
        "${SHADER_SLANG_FILES}"
        "${SHADER_OUTPUT_DIR}"
        GENERATED_SHADER_HEADERS
        EXTRA_FLAGS ${SHADER_INCLUDE_FLAGS}
    )

    compile_glsl(
        "${SHADER_GLSL_FILES}"
        "${SHADER_OUTPUT_DIR}"
        GENERATED_SHADER_GLSL_HEADERS
        EXTRA_FLAGS ${SHADER_INCLUDE_FLAGS}
    )
    
    # Add shader files to the project
    source_group("Shaders" FILES ${SHADER_SLANG_FILES} ${SHADER_GLSL_FILES} ${SHADER_H_FILES})
    source_group("Shaders/Compiled" FILES ${GENERATED_SHADER_SLANG_HEADERS} ${GENERATED_SHADER_GLSL_HEADERS} ${GENERATED_SHADER_HEADERS})

    # Add the output shader headers (target) directly to the executable (This allow to compile the shaders when the executable is built)
    target_sources(${SHADER_PROJECT_NAME} PRIVATE 
        ${SHADER_SLANG_FILES} 
        ${SHADER_GLSL_FILES}
        ${SHADER_H_FILES}
        ${GENERATED_SHADER_SLANG_HEADERS} 
        ${GENERATED_SHADER_GLSL_HEADERS} 
    )

    # for debug
    message(STATUS "compile_shaders: successfully config Shader Compile：")
    message(STATUS "  - Target：${SHADER_PROJECT_NAME}")
    message(STATUS "  - Output directory：${SHADER_OUTPUT_DIR}")
    message(STATUS "  - Include .h.slang：${SHADER_INCLUDE_H_SLANG_FILES}")
    message(STATUS "  - Enable foundation.slang：${SHADER_USE_FOUNDATION_SHADER}")
endfunction()


# Usage:
#   sakura_copy_resources(
#     [SHADER_SOURCE_DIR <dir>]        # Source shader directory（Default：${CMAKE_CURRENT_LIST_DIR}/shaders）
#     [DEST_ROOT_DIR <dir>]            # Target root directory（Default：${CMAKE_BINARY_DIR}/bin）
#     [AFTERMATH_DLLS <files>]         # Nsight Aftermath DLL file（optional, static lib doesn't need this）
#     [EXTRA_COPY_FILES <files>]       # Additional copy files      
#     [EXTRA_COPY_DIRECTORIES <dirs>]  # Additional copy directories
#   )

function(sakura_copy_resources)
    set(options "")  
    set(oneValueArgs
        SHADER_SOURCE_DIR  
        DEST_ROOT_DIR      
    )
    set(multiValueArgs
        AFTERMATH_DLLS     
        EXTRA_COPY_FILES   
        EXTRA_COPY_DIRECTORIES  
    )

    cmake_parse_arguments(RES "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})


    if(NOT DEFINED RES_SHADER_SOURCE_DIR)
        set(RES_SHADER_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/shaders")
    endif()

    if(NOT DEFINED RES_DEST_ROOT_DIR)
        set(RES_DEST_ROOT_DIR "${CMAKE_BINARY_DIR}/bin")
    endif()

    set(SHADER_DEST_DIR "${RES_DEST_ROOT_DIR}/shaders")


    # Copy shaders（only copy .glsl .slang ...）
    message(STATUS "\n Copy Resources（Destination directory：${RES_DEST_ROOT_DIR}）")
    if(EXISTS "${RES_SHADER_SOURCE_DIR}")
        file(COPY "${RES_SHADER_SOURCE_DIR}/" 
             DESTINATION "${SHADER_DEST_DIR}"
             FILES_MATCHING 
                 PATTERN "*.glsl" 
                 PATTERN "*.slang" 
                 PATTERN "*.h" 
                 PATTERN "*.h.slang"
             PATTERN ".git" EXCLUDE  
             PATTERN "*.txt" EXCLUDE 
        )
        message(STATUS "Copy Resources complete：")
        message(STATUS "   Source directory：${RES_SHADER_SOURCE_DIR}")
        message(STATUS "   Target directory：${SHADER_DEST_DIR}")
    else()
        message(WARNING "No Source directory：${RES_SHADER_SOURCE_DIR}")
    endif()


    # Additional file（include Nsight Aftermath DLL and custom files）
    set(ALL_COPY_FILES "")
    if(DEFINED RES_AFTERMATH_DLLS AND RES_AFTERMATH_DLLS)
        list(APPEND ALL_COPY_FILES ${RES_AFTERMATH_DLLS})
    endif()
    if(DEFINED RES_EXTRA_COPY_FILES AND RES_EXTRA_COPY_FILES)
        list(APPEND ALL_COPY_FILES ${RES_EXTRA_COPY_FILES})
    endif()

    # Execute copy 
    if(ALL_COPY_FILES)
        message(STATUS "\n Copy Additional Resources：")
        foreach(copy_file ${ALL_COPY_FILES})
            if(EXISTS "${copy_file}")
                file(COPY "${copy_file}" DESTINATION "${RES_DEST_ROOT_DIR}")
                get_filename_component(FILE_NAME "${copy_file}" NAME)
                message(STATUS "   - ${FILE_NAME}（源：${copy_file}）")
            else()
                message(WARNING "No Additional File：${copy_file}")
            endif()
        endforeach()
    else()
        message(STATUS "\n No need to copy additional files")
    endif()


    # Copy additional directory
    if(DEFINED RES_EXTRA_COPY_DIRECTORIES AND RES_EXTRA_COPY_DIRECTORIES)
        message(STATUS "\n Copy Additional Directory：")
        foreach(copy_dir ${RES_EXTRA_COPY_DIRECTORIES})
            if(EXISTS "${copy_dir}")
                get_filename_component(DIR_NAME "${copy_dir}" NAME)
                set(DIR_DEST "${RES_DEST_ROOT_DIR}/${DIR_NAME}")
                file(COPY "${copy_dir}/" DESTINATION "${DIR_DEST}")
                message(STATUS "   - ${DIR_NAME}（Source：${copy_dir} → Target：${DIR_DEST}）")
            else()
                message(WARNING "No Additional File：${copy_dir}")
            endif()
        endforeach()
    else()
        message(STATUS "\n No need to copy additional files")
    endif()

    message(STATUS "---- resource copy end ----\n")
endfunction()