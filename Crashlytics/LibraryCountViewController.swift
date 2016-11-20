//
//  ViewController.swift
//  Crashlytics
//
//  Created by Mayank Kumar on 11/7/16.
//  Copyright © 2016 Mayank Kumar. All rights reserved.
//

import UIKit

class LibraryCountViewController: UIViewController {

    @IBOutlet var libraryCountLabel: UILabel!
    @IBOutlet var loadedLibraryLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let loadedLibraryCount = DynamicLibraryTracker.loadedLibraryCount
        libraryCountLabel.text = loadedLibraryCount == 0 ? "First Run!" : "\(loadedLibraryCount)"
        loadedLibraryLabel.isHidden = loadedLibraryCount == 0
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}

