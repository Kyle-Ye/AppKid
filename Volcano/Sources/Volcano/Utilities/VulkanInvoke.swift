//
//  VulkanInvoke.swift
//  Volcano
//
//  Created by Serhii Mumriak on 17.05.2020.
//

public func vulkanInvoke(_ invocation: () -> (VkResult)) throws {
    let result: VkResult = invocation()
    if result != VK_SUCCESS {
        throw VulkanError.badResult(result)
    }
}

public func vulkanInvoke(_ invocation: @autoclosure () -> (VkResult)) throws {
    try vulkanInvoke {
        invocation()
    }
}

public func vulkanInvoke(_ invocation: () -> ()) throws {
    invocation()
}

public func vulkanInvoke(_ invocation: @autoclosure () -> ()) throws {
    invocation()
}
