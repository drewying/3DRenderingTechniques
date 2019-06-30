//
//  RendererProtocol.swift
//  RenderingTechniques
//
//  Created by Ingebretsen, Andrew (HBO) on 6/29/19.
//  Copyright © 2019 Drew Ingebretsen. All rights reserved.
//

import UIKit

protocol Renderer {
    init()
    func render(width: Int, height: Int) -> [[UIColor]]
}
