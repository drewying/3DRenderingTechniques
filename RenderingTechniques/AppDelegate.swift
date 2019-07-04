//
//  AppDelegate.swift
//  RenderingTechniques
//
//  Created by Drew Ingebretsen on 6/8/16.
//  Copyright © 2016 Drew Ingebretsen. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)

        let raycasterViewController = RenderViewController(renderer: RaycasterRenderer())
        raycasterViewController.title = "Raycasting"

        let rasterizationViewController = RenderViewController(renderer: RasterizerRenderer())
        rasterizationViewController.title = "Rasterization"

        let raytracerViewController = RenderViewController(renderer: RaytracerRenderer())
        raytracerViewController.title = "Raytracer"

        let viewController = UITabBarController()
        viewController.addChild(rasterizationViewController)
        viewController.addChild(raycasterViewController)
        viewController.addChild(raytracerViewController)

        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        return true
    }
}
