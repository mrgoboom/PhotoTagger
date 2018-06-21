//
//  PhotoViewController.swift
//  PhotoTagger
//
//  Created by Old iMac on 2018-06-20.
//  Copyright © 2018 Scott. All rights reserved.
//

import UIKit

class PhotoViewController : UIViewController {
    
    var imageArray: [UIImage]?
    var activeImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.view.viewWithTag(3) != nil{
            let imageView = self.view.viewWithTag(3) as! UIImageView
            self.activeImage = imageView.image
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setImageArray(images: [UIImage]){
        self.imageArray = images
    }
}
