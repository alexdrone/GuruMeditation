//
//  AppDelegate.swift
//  GuruDemo
//
//  Created by Alex Usbergo on 8/16/16.
//  Copyright © 2016 alexusbergo. All rights reserved.
//

import UIKit
import GuruMeditation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  func application(application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    return true
  }
}

class ViewController: UIViewController {

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    Guru.warning("Your error message goes here.")
  }
}

