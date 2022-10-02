//
//  Additions.h
//  Volcano
//  
//  Created by Serhii Mumriak on 01.10.2022
//

#ifndef Additions_h
#define Additions_h 1

#include <vulkan/vulkan.h>

#ifndef __cplusplus

static inline void * volcanoGetInstanceProcAddr(VkInstance instance, const char* pName)
{
    return vkGetInstanceProcAddr(instance, pName);
}

static inline void * volcanoGetDeviceProcAddr(VkDevice device, const char* pName)
{
    return vkGetDeviceProcAddr(device, pName);
}

typedef struct {
    VkPipelineCache pipelineCache;
} VolcanoGraphicsPipelineContext;

static VKAPI_ATTR VkResult VKAPI_CALL volcanoCreateGraphicsPipelines(
    VkDevice                                device,
    const VolcanoGraphicsPipelineContext*   pContext,
    uint32_t                                createInfoCount,
    const VkGraphicsPipelineCreateInfo*     pCreateInfos,
    const VkAllocationCallbacks*            pAllocator,
    VkPipeline*                             pPipelines)
{
    VkPipelineCache pipelineCache = NULL;

    if (pContext) {
        pipelineCache = pContext->pipelineCache;
    }

    return vkCreateGraphicsPipelines(
        device /* device */,
        pipelineCache /* pipelineCache */,
        createInfoCount /* createInfoCount */,
        pCreateInfos /* pCreateInfos */,
        pAllocator /* pAllocator */,
        pPipelines /* pPipelines */
    );
}

typedef struct {
    VkPipelineCache pipelineCache;
} VolcanoComputePipelineContext;

static VKAPI_ATTR VkResult VKAPI_CALL volcanoCreateComputePipelines(
    VkDevice                                device,
    const VolcanoComputePipelineContext*    pContext,
    uint32_t                                createInfoCount,
    const VkComputePipelineCreateInfo*      pCreateInfos,
    const VkAllocationCallbacks*            pAllocator,
    VkPipeline*                             pPipelines)
{
    VkPipelineCache pipelineCache = NULL;

    if (pContext) {
        pipelineCache = pContext->pipelineCache;
    }

    return vkCreateComputePipelines(
        device /* device */,
        pipelineCache /* pipelineCache */,
        createInfoCount /* createInfoCount */,
        pCreateInfos /* pCreateInfos */,
        pAllocator /* pAllocator */,
        pPipelines /* pPipelines */
    );
}

typedef struct {
    VkDeferredOperationKHR  deferredOperation;
    VkPipelineCache         pipelineCache;
} VolcanoRayTracingPipelineKHRContext;

static VKAPI_ATTR VkResult VKAPI_CALL volcanoCreateRayTracingPipelinesKHR(
    VkDevice                                    device,
    const VolcanoRayTracingPipelineKHRContext*  pContext,
    uint32_t                                    createInfoCount,
    const VkRayTracingPipelineCreateInfoKHR*    pCreateInfos,
    const VkAllocationCallbacks*                pAllocator,
    VkPipeline*                                 pPipelines)
{
    VkDeferredOperationKHR deferredOperation = NULL;
    VkPipelineCache pipelineCache = NULL;

    if (pContext) {
        deferredOperation = pContext->deferredOperation;
        pipelineCache = pContext->pipelineCache;
    }

    return vkCreateRayTracingPipelinesKHR(
        device /* device */,
        deferredOperation /* deferredOperation */,
        pipelineCache /* pipelineCache */,
        createInfoCount /* createInfoCount */,
        pCreateInfos /* pCreateInfos */,
        pAllocator /* pAllocator */,
        pPipelines /* pPipelines */
    );
}

typedef struct {
    VkPipelineCache pipelineCache;
} VolcanoRayTracingPipelineNVContext;

static VKAPI_ATTR VkResult VKAPI_CALL volcanoCreateRayTracingPipelinesNV(
    VkDevice                                    device,
    const VolcanoRayTracingPipelineNVContext*   pContext,
    uint32_t                                    createInfoCount,
    const VkRayTracingPipelineCreateInfoNV*     pCreateInfos,
    const VkAllocationCallbacks*                pAllocator,
    VkPipeline*                                 pPipelines)
{
    VkPipelineCache pipelineCache = NULL;

    if (pContext) {
        pipelineCache = pContext->pipelineCache;
    }

    return vkCreateRayTracingPipelinesNV(
        device /* device */,
        pipelineCache /* pipelineCache */,
        createInfoCount /* createInfoCount */,
        pCreateInfos /* pCreateInfos */,
        pAllocator /* pAllocator */,
        pPipelines /* pPipelines */
    );
}

#endif

#endif
