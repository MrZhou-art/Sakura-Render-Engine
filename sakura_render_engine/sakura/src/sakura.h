#pragma


#include <nvaftermath/aftermath.hpp>       // Nsight Aftermath for crash tracking and shader debugging
#include <nvapp/application.hpp>           // Application framework
#include <nvapp/elem_camera.hpp>           // Camera manipulator
#include <nvapp/elem_default_title.hpp>    // Default title element
#include <nvapp/elem_default_menu.hpp>     // Default menu element
#include <nvgui/camera.hpp>                // Camera widget
#include <nvgui/sky.hpp>                   // Sky widget
#include <nvgui/tonemapper.hpp>            // Tonemapper widget
#include <nvshaders_host/sky.hpp>          // Sky shader
#include <nvshaders_host/tonemapper.hpp>   // Tonemapper shader
#include <nvslang/slang.hpp>               // Slang compiler
#include <nvutils/camera_manipulator.hpp>  // Camera manipulator
#include <nvutils/logger.hpp>              // Logger for debug messages
#include <nvutils/timers.hpp>              // Timers for profiling
#include <nvvk/context.hpp>                // Vulkan context management
#include <nvvk/default_structs.hpp>        // Default Vulkan structures
#include <nvvk/descriptors.hpp>            // Descriptor set management
#include <nvvk/formats.hpp>                // Finding Vulkan formats utilities
#include <nvvk/gbuffers.hpp>               // GBuffer management
#include <nvvk/graphics_pipeline.hpp>      // Graphics pipeline management
#include <nvvk/sampler_pool.hpp>           // Sampler pool management
#include <nvvk/validation_settings.hpp>    // Validation settings for Vulkan
#include <nvutils/parameter_parser.hpp>    // Parameter parser

