//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        renderer = Renderer(metalView: view as! TouchMetalView)
        renderer.scene = Scene(withRenderer: renderer)
        
        let button = UIButton(type: .roundedRect)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Explode!", for: .normal)
        button.setTitleColor(UIColor(red: 1, green: 81 / 255, blue: 81 / 255, alpha: 1), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 30)
        view.addSubview(button)
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        button.addTarget(self, action: #selector(explode), for: .touchUpInside)
    }
    
    @objc private func explode() {
        Scene.isExploding = !Scene.isExploding
    }
}
