//
//  Queue.swift
//  Volcano
//
//  Created by Serhii Mumriak on 19.05.2020.
//

import Foundation
import TinyFoundation
import CVulkan

public final class Queue: HandleStorage<SmartPointer<VkQueue_T>> {
    public internal(set) unowned var device: Device
    public let familyIndex: Int
    public let queueIndex: Int
    public let type: VkQueueFlagBits

    private let lock = NSRecursiveLock()

    public init(device: Device, familyIndex: Int, queueIndex: Int, type: VkQueueFlagBits) throws {
        self.device = device
        self.familyIndex = familyIndex
        self.queueIndex = queueIndex
        self.type = type

        var handle: VkQueue?
        try vulkanInvoke {
            vkGetDeviceQueue(device.handle, CUnsignedInt(familyIndex), CUnsignedInt(queueIndex), &handle)
        }

        super.init(handlePointer: SmartPointer(with: handle!))
    }

    public func waitForIdle() throws {
        try vulkanInvoke {
            vkQueueWaitIdle(handle)
        }
    }

    public func submit(with descriptor: SubmitDescriptor) throws {
        #if EXPERIMENTAL_VOLCANO_DSL
            try VkBuilder<VkSubmitInfo> {
                (\.waitSemaphoreCount, \.pWaitSemaphores) <- descriptor.waitSemaphores
                (\.signalSemaphoreCount, \.pSignalSemaphores) <- descriptor.signalSemaphores
                \.pWaitDstStageMask <- descriptor.waitStages
                (\.commandBufferCount, \.pCommandBuffers) <- descriptor.commandBuffers
                if descriptor.hasTimeline {
                    <-VkBuilder<VkTimelineSemaphoreSubmitInfo> {
                        (\.waitSemaphoreValueCount, \.pWaitSemaphoreValues) <- descriptor.waitSemaphoreValues
                        (\.signalSemaphoreValueCount, \.pSignalSemaphoreValues) <- descriptor.signalSemaphoreValues
                    }
                }
            }
            .withUnsafeResultPointer { info in
                try lock.synchronized {
                    try vulkanInvoke {
                        vkQueueSubmit(handle, 1, info, descriptor.fence?.handle)
                    }
                }
            }
        #else
            try descriptor.commandBuffers.optionalHandles().withUnsafeBufferPointer { commandBuffers in
                try descriptor.waitSemaphores.optionalHandles().withUnsafeBufferPointer { waitSemaphores in
                    try descriptor.waitSemaphoreValues.withUnsafeBufferPointer { waitSemaphoreValues in
                        try descriptor.waitStages.withUnsafeBufferPointer { waitStages in
                            try descriptor.signalSemaphores.optionalHandles().withUnsafeBufferPointer { signalSemaphores in
                                try descriptor.signalSemaphoreValues.withUnsafeBufferPointer { signalSemaphoreValues in
                                    var info: VkSubmitInfo = .new()

                                    info.waitSemaphoreCount = CUnsignedInt(waitSemaphores.count)
                                    info.pWaitSemaphores = waitSemaphores.baseAddress!

                                    info.signalSemaphoreCount = CUnsignedInt(signalSemaphores.count)
                                    info.pSignalSemaphores = signalSemaphores.baseAddress!

                                    info.pWaitDstStageMask = waitStages.baseAddress!

                                    info.commandBufferCount = CUnsignedInt(commandBuffers.count)
                                    info.pCommandBuffers = commandBuffers.baseAddress!

                                    let chain = VulkanStructureChain(root: info)

                                    if descriptor.hasTimeline {
                                        var timelineInfo: VkTimelineSemaphoreSubmitInfo = .new()
                                        timelineInfo.waitSemaphoreValueCount = CUnsignedInt(waitSemaphoreValues.count)
                                        timelineInfo.pWaitSemaphoreValues = waitSemaphoreValues.baseAddress!
                                        timelineInfo.signalSemaphoreValueCount = CUnsignedInt(signalSemaphoreValues.count)
                                        timelineInfo.pSignalSemaphoreValues = signalSemaphoreValues.baseAddress!

                                        chain.append(timelineInfo)
                                    }

                                    try lock.synchronized {
                                        try chain.withUnsafeChainPointer { info in
                                            try vulkanInvoke {
                                                vkQueueSubmit(handle, 1, info, descriptor.fence?.handle)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        #endif
    }

    public func present(swapchains: [Swapchain],
                        waitSemaphores: [Volcano.Semaphore] = [],
                        imageIndices: [CUnsignedInt]) throws {
        let swapchainsHandles: [VkSwapchainKHR?] = swapchains.map { $0.handle }
        let waitSemaphoresHandles: [VkSemaphore?] = waitSemaphores.map { $0.handle }

        try imageIndices.withUnsafeBufferPointer { imageIndicesPointer in
            try waitSemaphoresHandles.withUnsafeBufferPointer { waitSemaphoresPointer in
                try swapchainsHandles.withUnsafeBufferPointer { swapchainsPointer in
                    var presentInfo = VkPresentInfoKHR()
                    presentInfo.sType = .presentInfoKhr

                    presentInfo.waitSemaphoreCount = CUnsignedInt(waitSemaphoresPointer.count)
                    presentInfo.pWaitSemaphores = waitSemaphoresPointer.baseAddress

                    presentInfo.swapchainCount = CUnsignedInt(swapchainsPointer.count)
                    presentInfo.pSwapchains = swapchainsPointer.baseAddress!

                    presentInfo.pImageIndices = imageIndicesPointer.baseAddress!
                    presentInfo.pResults = nil

                    try lock.synchronized {
                        try vulkanInvoke {
                            device.vkQueuePresentKHR(handle, &presentInfo)
                        }
                    }
                }
            }
        }
    }

    public func oneShot(in commandPool: CommandPool, wait: Bool, semaphores: [TimelineSemaphore] = [], disposalBag: DisposalBag? = nil, _ body: (_ commandBuffer: CommandBuffer) throws -> ()) throws {
        let commandBuffer = try commandPool.createCommandBuffer()
        disposalBag?.append(commandBuffer)

        let fence: Fence? = wait ? try Fence(device: device) : nil
        if let fence = fence {
            disposalBag?.append(fence)
        }

        try fence?.reset()

        try commandBuffer.begin(flags: .oneTimeSubmit)

        try body(commandBuffer)

        try commandBuffer.end()

        let descriptor = SubmitDescriptor(commandBuffers: [commandBuffer], fence: fence)
        try semaphores.forEach {
            try descriptor.add(.signal($0))
        }

        try submit(with: descriptor)
        
        try fence?.wait()
    }

    public func createCommandPool(flags: VkCommandPoolCreateFlagBits = .resetCommandBuffer) throws -> CommandPool {
        try CommandPool(device: device, queue: self, flags: flags)
    }
}

public extension Array where Element == Queue {
    var familyIndices: [CUnsignedInt] {
        return Array<CUnsignedInt>(Set(map { CUnsignedInt($0.familyIndex) }))
    }
}

public struct WaitDescriptor {
    public let semaphore: AbstractSemaphore
    public let value: UInt64
    public let waitStages: VkPipelineStageFlagBits

    public init(semaphore: Semaphore, waitStages: VkPipelineStageFlagBits) throws {
        self.semaphore = semaphore
        self.value = 0
        self.waitStages = waitStages
    }

    public init(timelineSemaphore: TimelineSemaphore, value: UInt64? = nil, waitStages: VkPipelineStageFlagBits) throws {
        self.semaphore = timelineSemaphore
        self.value = try value ?? (timelineSemaphore.value + 1)
        self.waitStages = waitStages
    }

    public static func wait(_ semaphore: Semaphore, stages: VkPipelineStageFlagBits) throws -> Self {
        return try Self(semaphore: semaphore, waitStages: stages)
    }

    public static func wait(_ timelineSemaphore: TimelineSemaphore, value: UInt64? = nil, stages: VkPipelineStageFlagBits) throws -> Self {
        return try Self(timelineSemaphore: timelineSemaphore, value: value, waitStages: stages)
    }
}

public struct SignalDescriptor {
    public let semaphore: AbstractSemaphore
    public let value: UInt64

    public init(semaphore: Semaphore) throws {
        self.semaphore = semaphore
        self.value = 0
    }

    public init(timelineSemaphore: TimelineSemaphore, value: UInt64? = nil) throws {
        self.semaphore = timelineSemaphore
        self.value = try value ?? (timelineSemaphore.value + 1)
    }

    public static func signal(_ semaphore: Semaphore) throws -> Self {
        return try Self(semaphore: semaphore)
    }

    public static func signal(_ timelineSemaphore: TimelineSemaphore, value: UInt64? = nil) throws -> Self {
        return try Self(timelineSemaphore: timelineSemaphore, value: value)
    }
}

public class SubmitDescriptor {
    internal let commandBuffers: [CommandBuffer]
    internal var waitSemaphores: [AbstractSemaphore] = []
    internal var waitSemaphoreValues: [UInt64] = []
    internal var waitStages: [VkPipelineStageFlags] = []

    internal var signalSemaphores: [AbstractSemaphore] = []
    internal var signalSemaphoreValues: [UInt64] = []
    internal let fence: Fence?

    internal var hasTimeline: Bool = false

    public init(commandBuffers: [CommandBuffer], fence: Fence? = nil) {
        assert(commandBuffers.count > 0)

        self.commandBuffers = commandBuffers
        self.fence = fence
    }

    public func add(_ descriptor: WaitDescriptor) {
        waitSemaphores.append(descriptor.semaphore)
        waitSemaphoreValues.append(descriptor.value)
        waitStages.append(descriptor.waitStages.rawValue)

        if descriptor.value != 0 {
            hasTimeline = true
        }
    }

    public func add(_ descriptor: SignalDescriptor) {
        signalSemaphores.append(descriptor.semaphore)
        signalSemaphoreValues.append(descriptor.value)

        if descriptor.value != 0 {
            hasTimeline = true
        }
    }
}
