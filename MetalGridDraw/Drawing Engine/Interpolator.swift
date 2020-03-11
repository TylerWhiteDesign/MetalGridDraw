//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import UIKit

class Interpolator
{
    static func pointsBetween(firstPoint: float2, secondPoint: float2, distanceBetween: Float) -> [float2] {
        var points = [float2]()
        
        let x1 = firstPoint.x
        let y1 = firstPoint.y
        let x2 = secondPoint.x
        let y2 = secondPoint.y
        
        let distX = x2 - x1
        let distY = y2 - y1
        let dist = sqrt(distX * distX + distY * distY)
        
        if dist < distanceBetween {
            return points
        }
        
        let betweenCount = Int(floor(dist / distanceBetween))
        for i in 1...betweenCount {
            let r = Float(i) / Float(betweenCount + 1)
            let point = float2(x1 + r*(x2-x1), y1 + r*(y2-y1))
            points.append(point)
        }
        
        return points
    }
}
