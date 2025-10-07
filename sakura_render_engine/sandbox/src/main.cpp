#include <sakura/Elements/ElementFoundation.hpp>


//---------------------------------------------------------------------------------------------------------------
// The main function, entry point of the application
int main(int argc, char** argv)
{
    nvapp::ApplicationCreateInfo appInfo{};

    // Parsing the command line
    nvutils::ParameterParser   cli(nvutils::getExecutablePath().stem().string());
    nvutils::ParameterRegistry reg;
    reg.add({ "headless", "Run in headless mode" }, &appInfo.headless, true);
    cli.add(reg);
    cli.parse(argc, argv);

    // Setting up the Vulkan context, instance and device extensions
    VkPhysicalDeviceShaderObjectFeaturesEXT shaderObjectFeatures
    { .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_OBJECT_FEATURES_EXT };
    nvvk::ContextInitInfo vkSetup{
        .instanceExtensions = {VK_EXT_DEBUG_UTILS_EXTENSION_NAME},
        .deviceExtensions =
            {
                {VK_KHR_PUSH_DESCRIPTOR_EXTENSION_NAME},
                {VK_EXT_SHADER_OBJECT_EXTENSION_NAME, &shaderObjectFeatures},
            },
    };
    if (!appInfo.headless)
    {
        nvvk::addSurfaceExtensions(vkSetup.instanceExtensions);
        vkSetup.deviceExtensions.push_back({ VK_KHR_SWAPCHAIN_EXTENSION_NAME });
    }

    // Adding control on the validation layers
    nvvk::ValidationSettings validationSettings;
    validationSettings.setPreset(nvvk::ValidationSettings::LayerPresets::eStandard);
    vkSetup.instanceCreateInfoExt = validationSettings.buildPNextChain();

#if defined(USE_NSIGHT_AFTERMATH)
    // Adding the Aftermath extension to the device and initialize the Aftermath
    auto& aftermath = AftermathCrashTracker::getInstance();
    aftermath.initialize();
    aftermath.addExtensions(vkSetup.deviceExtensions);
    // The callback function is called when a validation error is triggered. This will wait to give time to dump the GPU crash.
    nvvk::CheckError::getInstance().setCallbackFunction([&](VkResult result) { aftermath.errorCallback(result); });
#endif

    // Initialize the Vulkan context
    nvvk::Context vkContext;
    if (vkContext.init(vkSetup) != VK_SUCCESS)
    {
        LOGE("Error in Vulkan context creation\n");
        return 1;
    }

    // Setting up the application
    appInfo.name = "Sakura Render Engine";
    appInfo.instance = vkContext.getInstance();
    appInfo.device = vkContext.getDevice();
    appInfo.physicalDevice = vkContext.getPhysicalDevice();
    appInfo.queues = vkContext.getQueueInfos();

    // Create the application
    nvapp::Application application;
    application.init(appInfo);

    // Elements added to the application
    auto foundation = std::make_shared<ElementFoundation>();          // Our tutorial element
    auto elemCamera = std::make_shared<nvapp::ElementCamera>();  // Element to control the camera movement
    auto windowTitle = std::make_shared<nvapp::ElementDefaultWindowTitle>();  // Element displaying the window title with application name and size
    auto windowMenu = std::make_shared<nvapp::ElementDefaultMenu>();  // Element displaying a menu, File->Exit ...
    auto camManip = foundation->getCameraManipulator();
    elemCamera->setCameraManipulator(camManip);

    // Adding all elements
    application.addElement(windowMenu);
    application.addElement(windowTitle);
    application.addElement(elemCamera);
    application.addElement(foundation);

    application.run();     // Start the application, loop until the window is closed
    application.deinit();  // Closing application
    vkContext.deinit();    // De-initialize the Vulkan context

    return 0;
}

