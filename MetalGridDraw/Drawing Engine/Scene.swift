//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import MetalKit
import Promises

class Scene
{
    private(set) weak var renderer: Renderer!
    private(set) var cells = [Cell]()
    private(set) var cellInstances: CellInstances?
    private let strokePointsInterpolatedDistance: Float = 0.01
    private var lastStrokeCell: Cell?
    private var lastStrokePoint: float2?
    static var isExploding = false
    static let columns = 100
    static let rows = 100
    
    //MARK: - Init
    
    init(withRenderer renderer: Renderer) {
        self.renderer = renderer
        self.renderer.uniforms.viewMatrix = float4x4.identity()
        self.renderer.uniforms.modelMatrix = float4x4.identity()
        reset()
    }
    
    //MARK: - Public
    
    func reset(includingCamera: Bool = false) {
        cells.removeAll()
        setupGrid()
        cellInstances = CellInstances(withCells: cells, renderer: renderer)
        
        // Set camera here
        updateViewMatrix()
    }
    
    func updateViewMatrix() {
        let cameraCenter = float3(0.5, 0.5, 0)
        let translationMatrix = float4x4(translation: cameraCenter).inverse
        
        let scaleTranslationMatrix = float4x4(translation: cameraCenter)
        let scaleMatrix = float4x4(scaling: [2, 2, 1])
        
        renderer.uniforms.viewMatrix = translationMatrix * scaleTranslationMatrix * scaleMatrix * scaleTranslationMatrix.inverse
    }
    
    func cellAtWorldPoint(_ point: float2) -> Promise<(Cell?, Int?)> {
        return Promise { fulfill, reject in
            self.cellInstances?.computeHit(withPoint: point).then { cellIndex in
                guard let cellIndex = cellIndex else {
                    fulfill((nil, nil))
                    return
                }
                
                fulfill((self.cells[Int(cellIndex)], Int(cellIndex)))
                return
            }
        }
    }
    
    //MARK: - Setup
    
    private func setupGrid() {
        let columns = Scene.columns
        let rows = Scene.rows
        let origin = float2(0, 0)
        let baseScale = 1 / Float(columns)
        let cellSize = 1 / Float(columns)
        let halfCellSize = cellSize / 2
        for row in 0..<rows {
            var gridRow = [Cell]()
            for col in 0..<columns {
                let center = float2(Float(col) * cellSize + halfCellSize + origin.x, Float(row) * cellSize + halfCellSize + origin.y)
                let cell = Cell(withBaseScale: baseScale, totalLevels: 5, center: center)
                gridRow.append(cell)
                cells.append(cell)
            }
        }
    }
    
    //MARK: - Rendering

    func render(withCommandBuffer commandBuffer: MTLCommandBuffer, renderEncoder: MTLRenderCommandEncoder, uniforms: Uniforms) {
        guard let cellInstances = cellInstances else {
            print("No cell instances object.")
            return
        }
        
        cellInstances.render(withRenderEncoder: renderEncoder, uniforms: uniforms)
        
        renderEncoder.endEncoding()
        
        cellInstances.computeMatrix(withCommandBuffer: commandBuffer)
    }
    
    //MARK: - Drawing
    
    func touchCellAtWorldPoint(_ point: float2) {
        cellAtWorldPoint(point).then { (cell, index) in
            guard let cell = cell else {
                return
            }
            
            cell.tapped()
        }
    }
    
    func strokeAtNextWorldPoint(_ point: float2, didEnd: Bool) {
        var interpolatedPoints = [float2]()
        if let lastStrokePoint = lastStrokePoint {
            interpolatedPoints.append(lastStrokePoint)
            interpolatedPoints.append(contentsOf: Interpolator.pointsBetween(firstPoint: lastStrokePoint, secondPoint: point, distanceBetween: strokePointsInterpolatedDistance))
            if didEnd {
                interpolatedPoints.append(point)
            }
        }

        for interpolatedPoint in interpolatedPoints {
            cellAtWorldPoint(interpolatedPoint).then { (cell, index) in
                guard let currentCell = cell else {
                    return
                }
                
                guard let lastCell = self.lastStrokeCell else {
                    currentCell.tapped()
                    self.lastStrokeCell = currentCell
                    return
                }

                if currentCell != lastCell {
                    currentCell.tapped()
                    self.lastStrokeCell = currentCell
                }
            }
        }
        lastStrokePoint = point

        if didEnd {
            lastStrokeCell = nil
            lastStrokePoint = nil
        }
    }
    
    //MARK: - Coordinate Spaces
    
    func convertFromUIKitSpaceToNDCSpace(_ point: CGPoint, inSize size: CGSize, isVector: Bool) -> float2 {
        var ndcPoint = float2((Float(point.x) / Float(size.width)) * renderer.ndcSpan.x, (Float(point.y) / Float(size.height)) * renderer.ndcSpan.y)
        if !isVector {
            ndcPoint = float2(ndcPoint.x - 1, ndcPoint.y - 1)
        }
        ndcPoint.y = -ndcPoint.y
        return ndcPoint
    }
    
    func convertFromNDCSpaceToViewSpace(_ point: float2, isVector: Bool) -> float2 {
        let viewPoint = renderer.uniforms.projectionMatrix.inverse * float4(point.x, point.y, 0, isVector ? 0 : 1)
        return float2(viewPoint.x, viewPoint.y)
    }
    
    func convertFromViewSpaceToWorldSpace(_ point: float2, isVector: Bool) -> float2 {
        let worldPoint = renderer.uniforms.viewMatrix.inverse * float4(point.x, point.y, 0, isVector ? 0 : 1)
        return float2(worldPoint.x, worldPoint.y)
    }
}

extension Scene: TouchMetalViewDelegate
{
    func touchMetalView(_ touchMetalView: TouchMetalView, didPanWithPanGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer) {
        let uiKitPoint = panGestureRecognizer.location(in: touchMetalView)
        let ndcPoint = convertFromUIKitSpaceToNDCSpace(uiKitPoint, inSize: touchMetalView.bounds.size, isVector: false)
        let viewPoint = convertFromNDCSpaceToViewSpace(ndcPoint, isVector: false)
        let worldPoint = convertFromViewSpaceToWorldSpace(viewPoint, isVector: false)
        strokeAtNextWorldPoint(worldPoint, didEnd: panGestureRecognizer.state == .ended)
    }
    
    func touchMetalView(_ touchMetalView: TouchMetalView, didTapAtPoint point: CGPoint) {
        let ndcPoint = convertFromUIKitSpaceToNDCSpace(point, inSize: touchMetalView.bounds.size, isVector: false)
        let viewPoint = convertFromNDCSpaceToViewSpace(ndcPoint, isVector: false)
        let worldPoint = convertFromViewSpaceToWorldSpace(viewPoint, isVector: false)
        touchCellAtWorldPoint(worldPoint)
    }
}
