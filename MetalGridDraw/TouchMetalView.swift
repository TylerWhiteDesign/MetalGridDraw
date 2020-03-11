//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import MetalKit

protocol TouchMetalViewDelegate: class
{
    func touchMetalView(_ touchMetalView: TouchMetalView, didTapAtPoint point: CGPoint)
    func touchMetalView(_ touchMetalView: TouchMetalView, didPanWithPanGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer)
}

class TouchMetalView: MTKView
{
    weak var touchDelegate: TouchMetalViewDelegate?
    private let tapQualifyingDistanceThreshold: CGFloat = 5
    private var currentTouchesStartPoints = [UITouch: CGPoint]()
    
    //MARK: Init
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setup()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    //MARK: - Private
    
    private func setup() {
        isMultipleTouchEnabled = true
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        panGestureRecognizer.maximumNumberOfTouches = 2
        addGestureRecognizer(panGestureRecognizer)
    }
    
    private func processTouchesForQualifyingTaps(_ touches: Set<UITouch>) {
        for touch in touches {
            guard let startPoint = currentTouchesStartPoints[touch] else {
                continue
            }
            
            let endPoint = touch.location(in: self)
            let distX = endPoint.x - startPoint.x
            let distY = endPoint.y - startPoint.y
            let dist = sqrt(distX * distX + distY * distY)
            if dist <= tapQualifyingDistanceThreshold {
                touchDelegate?.touchMetalView(self, didTapAtPoint: startPoint)
            }
        }
    }
    
    //MARK: Public
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            currentTouchesStartPoints[touch] = touch.location(in: self)
        }
        
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        processTouchesForQualifyingTaps(touches)
        for touch in touches {
            currentTouchesStartPoints.removeValue(forKey: touch)
        }
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            currentTouchesStartPoints.removeValue(forKey: touch)
        }
        super.touchesCancelled(touches, with: event)
    }
    
    //MARK: - Actions
    
    @objc private func pan(_ panGestureRecognizer: UIPanGestureRecognizer) {
        touchDelegate?.touchMetalView(self, didPanWithPanGestureRecognizer: panGestureRecognizer)
    }
}
