#pragma once 

#ifdef _WIN32
	#ifdef SAKURA_DLL_EXPORT
		#define SAKURA_API __declspec(dllexport)
	#else
		#define SAKURA_API __declspec(dllimport)
	#endif
#else
	#define SAKURA_API
#endif




#include <glm/glm.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <imgui/imgui.h>
#include <imgui/backends/imgui_impl_vulkan.h>

#include "shaders/shaderio.h"


// Pre-compiled shaders
#include "_autogen/sky_simple.slang.h"  // from nvpro_core2
#include "_autogen/tonemapper.slang.h"  //   "    "
#include "_autogen/foundation.slang.h"  // Local shader


#include <sakura.h>

#include "common/gltf_utils.hpp"  // GLTF utilities for loading and importing GLTF models
#include "common/utils.hpp"       // Common utilities for the sample application
#include "common/path_utils.hpp"  // Path utilities for handling resources file paths


class ElementFoundation : public nvapp::IAppElement
{
	// Type of GBuffers
	enum
	{
		eImgRendered,
		eImgTonemapped
	};

public:

	ElementFoundation() = default;
	~ElementFoundation() = default;

	virtual void onAttach(nvapp::Application* app) override;
	virtual void onDetach() override;
	virtual void onResize(VkCommandBuffer cmd, const VkExtent2D& size) override;
	virtual void onUIRender() override;
	virtual void onUIMenu() override;
	virtual void onRender(VkCommandBuffer cmd) override;
	virtual void onLastHeadlessFrame() override;

	void createScene();
	void createGraphicsDescriptorSetLayout();
	void createGraphicsPipelineLayout();
	void updateTextures();
	VkShaderModuleCreateInfo compileSlangShader(const std::filesystem::path& filename, const std::span<const uint32_t>& spirv);
	void compileAndCreateGraphicsShaders();
	void updateSceneBuffer(VkCommandBuffer cmd);
	void rasterScene(VkCommandBuffer cmd);
	void postProcess(VkCommandBuffer cmd);



	// Accessor for camera manipulator
	std::shared_ptr<nvutils::CameraManipulator> getCameraManipulator() const { return m_cameraManip; }
private:
	// Application and core components
	nvapp::Application* m_app{};             // The application framework
	nvvk::ResourceAllocator m_allocator{};       // Resource allocator for Vulkan resources, used for buffers and images
	nvvk::StagingUploader  m_stagingUploader{};  // Utility to upload data to the GPU, used for staging buffers and images
	nvvk::SamplerPool      m_samplerPool{};      // Texture sampler pool, used to acquire texture samplers for images
	nvvk::GBuffer          m_gBuffers{};         // The G-Buffer
	nvslang::SlangCompiler m_slangCompiler{};    // The Slang compiler used to compile the shaders

	// Camera manipulator
	std::shared_ptr<nvutils::CameraManipulator> m_cameraManip{ std::make_shared<nvutils::CameraManipulator>() };

	// Pipeline
	nvvk::GraphicsPipelineState m_dynamicPipeline;  // The dynamic pipeline state used to set the graphics pipeline state, like viewport, scissor, and depth test
	nvvk::DescriptorPack m_descPack;  // The descriptor bindings used to create the descriptor set layout and descriptor sets
	VkPipelineLayout m_graphicPipelineLayout{};  // The pipeline layout use with graphics pipeline

	// Shaders
	VkShaderEXT m_vertexShader{};    // The vertex shader used to render the scene
	VkShaderEXT m_fragmentShader{};  // The fragment shader used to render the scene


	// Scene information buffer (UBO)
	nvsamples::GltfSceneResource m_sceneResource{};  // The GLTF scene resource, contains all the buffers and data for the scene
	std::vector<nvvk::Image> m_textures{};           // Textures used in the scene

	nvshaders::SkySimple     m_skySimple{};       // Sky rendering
	nvshaders::Tonemapper    m_tonemapper{};      // Tonemapper for post-processing effects
	shaderio::TonemapperData m_tonemapperData{};  // Tonemapper data used to pass parameters to the tonemapper shader
	glm::vec2 m_metallicRoughnessOverride{ -0.01f, -0.01f };  // Override values for metallic and roughness, used in the UI to control the material properties
};