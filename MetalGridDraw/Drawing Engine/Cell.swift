//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import MetalKit

class Cell
{
    var center: float2
    var levelMax: Int {
        didSet {
            scaleCurrentLevelFromOldLevelMax(oldValue)
        }
    }
    private var levelScale: Float = 1
    private let baseScale: Float
    private let levelScaleMin: Float = 0.6
    private let levelScaleMax: Float = 1.2
    private let zeroScale: Float = 0.001
    
    var currentLevel = 0 {
        didSet {
            updateCurrentLevelModeAttribute()
            updateInstanceAttributes()
        }
    }
    var color: float3 = [1, 1, 1]
            
    var instanceAttributes = CellInstanceAttributes()
    var velocity = float2(0, 0)
    
    //MARK: - Init
    
    init(withBaseScale baseScale: Float, totalLevels: Int, center: float2) {
        self.baseScale = baseScale
        self.center = center
        self.levelMax = totalLevels
        
        velocity = float2(Float.random(in: 0.0001...0.001) - 0.0005, Float.random(in: 0.0001...0.001) - 0.0005)
        updateInstanceAttributes()
    }
    
    //MARK: - Public
    
    func reset() {
        currentLevel = 0
    }
    
    func tapped() {
        currentLevel = max(min(currentLevel + 1, levelMax), 0)
    }
    
    //MARK: - Private
    
    private func scaleCurrentLevelFromOldLevelMax(_ oldValue: Int) {
        let scale = Float(levelMax) / Float(oldValue + 1)
        currentLevel = Int(Float(currentLevel) * scale)
    }
    
    private func updateCurrentLevelModeAttribute() {
        let colorValue = Float((255 - (Float(currentLevel) * (Float(255) / Float(levelMax)))) / 255)
        color = [colorValue, colorValue, colorValue]
    }
    
    private func updateInstanceAttributes() {
        instanceAttributes.scaleMatrix = float4x4(scaling: [baseScale, baseScale, baseScale])
        instanceAttributes.color = color
    }
    
    //MARK: - Static
    
    typealias VerticesAndIndices = (vertices: [float3], indexes: [UInt16])
    
    static func newVerticesAndIndices() -> VerticesAndIndices {
        var vertices = [float3]()
        var indexes = [UInt16]()
        vertices.append([-0.5, -0.5, 0])
        vertices.append([-0.5, 0.5, 0])
        vertices.append([0.5, 0.5, 0])
        vertices.append([0.5, -0.5, 0])
        
        indexes.append(0)
        indexes.append(1)
        indexes.append(2)
        indexes.append(0)
        indexes.append(2)
        indexes.append(3)
        
        return (vertices: vertices, indexes: indexes)
    }
}

extension Cell: Equatable
{
    static func == (lhs: Cell, rhs: Cell) -> Bool {
        lhs.center == rhs.center
    }
}
