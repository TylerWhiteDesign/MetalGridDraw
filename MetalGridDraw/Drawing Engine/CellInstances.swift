//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import MetalKit
import Promises

class CellInstances
{
    private let cells: [Cell]
    private var renderPipelineState: MTLRenderPipelineState!
    private var computeMatrixPipelineState: MTLComputePipelineState!
    private var computeHitPipelineState: MTLComputePipelineState!
    private var vertices: [float3]?
    private var vertexIndices: [UInt16]?
    private var vertexBuffer: MTLBuffer?
    private var vertexIndexBuffer: MTLBuffer?
    private var instancesBuffer: MTLBuffer?
    private let renderer: Renderer
    
    //MARK: Init
    
    init(withCells cells: [Cell], renderer: Renderer) {
        self.renderer = renderer
        self.cells = cells
        setupBaseGeometry(withDevice: renderer.device)
        setupPipelineStates(withRenderer: renderer)
        setupInstancesBuffer(withDevice: renderer.device, instances: cells.count)
    }
    
    //MARK: Private
    
    private func setupInstancesBuffer(withDevice device: MTLDevice, instances: Int) {
        instancesBuffer = device.makeBuffer(length: instances * MemoryLayout<CellInstanceAttributes>.stride, options: [])
    }
    
    private func setupBaseGeometry(withDevice device: MTLDevice) {
        let verticesAndIndexes = Cell.newVerticesAndIndices()
        vertices = verticesAndIndexes.vertices
        vertexIndices = verticesAndIndexes.indexes
        vertexBuffer = device.makeBuffer(bytes: vertices!, length: vertices!.count * MemoryLayout<float3>.stride, options: .storageModeShared)
        vertexIndexBuffer = device.makeBuffer(bytes: vertexIndices!, length: vertexIndices!.count * MemoryLayout<Int16>.stride, options: .storageModeShared)
    }
    
    private func setupPipelineStates(withRenderer renderer: Renderer) {
        do {
            guard let computeMatrixFunction = renderer.library.makeFunction(name: "compute_matrix") else {
                fatalError("Could not make compute matrix library function.")
            }
            
            //TODO: Use a MTLComputePipelineDescriptor to set `threadGroupSizeIsMultipleOfThreadExecutionWidth` to true
            computeMatrixPipelineState = try renderer.device.makeComputePipelineState(function: computeMatrixFunction)
            
            guard let computeHitFunction = renderer.library.makeFunction(name: "compute_hit") else {
                fatalError("Could not make compute hit library function.")
            }
            
            computeHitPipelineState = try renderer.device.makeComputePipelineState(function: computeHitFunction)
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = renderer.library.makeFunction(name: "vertex_instances")
            pipelineDescriptor.fragmentFunction = renderer.library.makeFunction(name: "fragment_instances")
            pipelineDescriptor.colorAttachments[0].pixelFormat = renderer.metalView.colorPixelFormat
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            
            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float2
            vertexDescriptor.attributes[0].bufferIndex = 0
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.layouts[0].stride = MemoryLayout<float3>.stride
            pipelineDescriptor.vertexDescriptor = vertexDescriptor
            
            renderPipelineState = try renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not setup pipeline states.")
        }
    }
    
    //MARK: - Public
    
    func computeHit(withPoint point: float2) -> Promise<UInt?> {
        return Promise { fulfill, reject in
            guard let commandBuffer = self.renderer.commandQueue.makeCommandBuffer(), let computeEncoder = commandBuffer.makeComputeCommandEncoder(), let hitIndexBuffer = self.renderer.device.makeBuffer(length: MemoryLayout<UInt>.stride, options: []) else {
                return
            }
            
            computeEncoder.setComputePipelineState(self.computeHitPipelineState)
            
            let width = self.computeMatrixPipelineState.threadExecutionWidth
            let threadGroupsPerGrid = MTLSizeMake(Int(ceil(Float(self.cells.count) / Float(width))), 1, 1)
            let threadsPerGroup = MTLSizeMake(width, 1, 1)
            computeEncoder.setBuffer(self.instancesBuffer, offset: 0, index: 0)
            var count = UInt(self.cells.count)
            computeEncoder.setBytes(&count, length: MemoryLayout<UInt>.size, index: 1)
            var dimension = 1 / Float(Scene.columns)
            computeEncoder.setBuffer(hitIndexBuffer, offset: 0, index: 2)
            var _point = point
            computeEncoder.setBytes(&_point, length: MemoryLayout<float2>.size, index: 3)
            computeEncoder.setBytes(&dimension, length: MemoryLayout<Float>.size, index: 4)
            if self.renderer.device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
                computeEncoder.dispatchThreads(MTLSizeMake(self.cells.count, 1, 1), threadsPerThreadgroup: threadsPerGroup)
            } else {
                computeEncoder.dispatchThreadgroups(threadGroupsPerGrid, threadsPerThreadgroup: threadsPerGroup)
            }
            computeEncoder.endEncoding()
            commandBuffer.addCompletedHandler { (commandBuffer) in
                let pointer = hitIndexBuffer.contents().bindMemory(to: UInt.self, capacity: 1)
                fulfill(pointer.pointee != 0 ? pointer.pointee - 1 : nil)
            }
            commandBuffer.commit()
        }
    }
    
    func computeMatrix(withCommandBuffer commandBuffer: MTLCommandBuffer) {
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        computeEncoder.setComputePipelineState(computeMatrixPipelineState)
        
        let width = computeMatrixPipelineState.threadExecutionWidth
        let threadGroupsPerGrid = MTLSizeMake(Int(ceil(Float(cells.count) / Float(width))), 1, 1)
        let threadsPerGroup = MTLSizeMake(width, 1, 1)
        computeEncoder.setBuffer(instancesBuffer, offset: 0, index: 0)
        var count = UInt(cells.count)
        computeEncoder.setBytes(&count, length: MemoryLayout<UInt>.size, index: 1)
        if renderer.device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
            computeEncoder.dispatchThreads(MTLSizeMake(cells.count, 1, 1), threadsPerThreadgroup: threadsPerGroup)
        } else {
            computeEncoder.dispatchThreadgroups(threadGroupsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        }
        computeEncoder.endEncoding()
    }
}

extension CellInstances: Renderable
{
    var name: String {
        return "Cell Instances"
    }
    
    func render(withRenderEncoder renderEncoder: MTLRenderCommandEncoder, uniforms: Uniforms) {
        renderEncoder.pushDebugGroup(name)
        renderEncoder.setRenderPipelineState(renderPipelineState)
        
        guard let vertexBuffer = vertexBuffer else {
            fatalError("No vertex buffer")
        }
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        var _uniforms = uniforms
        renderEncoder.setVertexBytes(&_uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        
        guard let instancesBuffer = instancesBuffer else {
            fatalError("No instances buffer.")
        }
        
        var pointer = instancesBuffer.contents().bindMemory(to: CellInstanceAttributes.self, capacity: cells.count)
        for cell in cells {
            if Scene.isExploding {
                cell.center = cell.center + cell.velocity * 4
            }
            pointer.pointee.center = cell.center
            pointer.pointee.scaleMatrix =  cell.instanceAttributes.scaleMatrix
            pointer.pointee.color = cell.instanceAttributes.color
            cell.instanceAttributes.modelMatrix = pointer.pointee.modelMatrix
            pointer = pointer.advanced(by: 1)
        }
        
        renderEncoder.setVertexBuffer(instancesBuffer, offset: 0, index: 2)
        
        guard let vertexIndexes = vertexIndices, let vertexIndexBuffer = vertexIndexBuffer else {
            fatalError("No vertex indexes or vertex index buffer")
        }
        
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: vertexIndexes.count, indexType: .uint16, indexBuffer: vertexIndexBuffer, indexBufferOffset: 0, instanceCount: cells.count)
        
        renderEncoder.popDebugGroup()
    }
}
