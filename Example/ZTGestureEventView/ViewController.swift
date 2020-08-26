//
//  ViewController.swift
//  ZTGestureEventView
//
//  Created by SkyerWalker on 08/26/2020.
//  Copyright (c) 2020 SkyerWalker. All rights reserved.
//

import UIKit
import ZTGestureEventView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let event = ZTGestureEventView()
        event.frame = view.bounds
        event.backgroundColor = .purple
        view.addSubview(event)
        
        event.touchesSingleTapAction = { point in
            print(point)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

