//
//  ViewController.swift
//  CustomeVedioPlayerUsingAVFoundation
//
//  Created by Akshaya Gunnepalli on 28/03/25.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var playerView: PlayerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(playerView)
        // Do any additional setup after loading the view.
        playerView.loadVideo(viewController: self)
    }


}

