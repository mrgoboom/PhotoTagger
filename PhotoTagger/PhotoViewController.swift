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
    var activeSelector: UIView?
    var rating = 0
    var colour = ""
        
    override func viewDidLoad() {
        super.viewDidLoad()
        let imageView = self.view.viewWithTag(3) as! UIImageView
        self.activeImage = imageView.image
        
        self.rating = 0
        self.rateStars(stars: 0)
        
        self.colour = "empty"
        self.pickColour(colour: "empty")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        let touch: UITouch? = touches.first
        if(touch?.view != activeSelector){
            self.hideSelector()
        }
    }
    
    func setImageArray(images: [UIImage]){
        self.imageArray = images
    }
  
    
    
    func hideSelector(){
        self.activeSelector?.isHidden = true
        self.activeSelector = nil
    }

    
    
    func rateStars(stars: Int){
        self.rating = stars
        let starView = self.view.viewWithTag(1)
        var i = 1
        while i <= stars {
            let button = starView?.viewWithTag(100+i) as! UIButton
            button.setTitle("★", for: UIControlState.normal)
            i += 1
        }
        while i <= 5 {
            let button = starView?.viewWithTag(100+i) as! UIButton
            button.setTitle("☆", for: UIControlState.normal)
            i += 1
        }
    }
    @IBAction func starButtonPressed(_ sender: UIButton) {
        let starButtonSelectors = self.view.viewWithTag(1)
        if starButtonSelectors!.isHidden{
            self.hideSelector()
            starButtonSelectors!.isHidden = false
            self.activeSelector = starButtonSelectors
        }else{
            self.hideSelector()
        }
    }
    
    
    
    @IBAction func rated1Star(_ sender: UIButton) {
        if(self.rating != 1){
            self.rateStars(stars: 1)
        }else{
            self.rateStars(stars: 0)
        }
    }
    @IBAction func rated2Star(_ sender: UIButton) {
        if(self.rating != 2){
            self.rateStars(stars: 2)
        }else{
            self.rateStars(stars: 0)
        }
    }
    @IBAction func rated3Star(_ sender: UIButton) {
        if(self.rating != 3){
            self.rateStars(stars: 3)
        }else{
            self.rateStars(stars: 0)
        }
    }
    @IBAction func rated4Star(_ sender: UIButton) {
        if(self.rating != 4){
            self.rateStars(stars: 4)
        }else{
            self.rateStars(stars: 0)
        }
    }
    @IBAction func rated5Star(_ sender: UIButton) {
        if(self.rating != 5){
            self.rateStars(stars: 5)
        }else{
            self.rateStars(stars: 0)
        }
    }
    
    
    
    @IBAction func openColourPicker(_ sender: UIButton) {
        let colourButtons = self.view.viewWithTag(2)
        if colourButtons!.isHidden{
            self.hideSelector()
            colourButtons!.isHidden = false
            self.activeSelector = colourButtons
        }else{
            self.hideSelector()
        }
    }
    func pickColour(colour: String) {
        self.colour = colour
        let fileString = colour + "_square"
        let colourImage = UIImage(named: fileString)?.withRenderingMode(.alwaysOriginal)
        colourPicker.setImage(colourImage, for: UIControlState.normal)
    }
    
    

    @IBAction func pickRed(_ sender: UIButton) {
        if self.colour != "red"{
            self.pickColour(colour: "red")
        }else{
            self.pickColour(colour: "empty")
        }
    }
    @IBAction func pickOrange(_ sender: UIButton) {
        if self.colour != "orange"{
            self.pickColour(colour: "orange")
        }else{
            self.pickColour(colour: "empty")
        }
    }
    @IBAction func pickYellow(_ sender: UIButton) {
        if self.colour != "yellow"{
            self.pickColour(colour: "yellow")
        }else{
            self.pickColour(colour: "empty")
        }
    }
    @IBAction func pickGreen(_ sender: UIButton) {
        if self.colour != "green"{
            self.pickColour(colour: "green")
        }else{
            self.pickColour(colour: "empty")
        }
    }
    @IBAction func pickBlue(_ sender: UIButton) {
        if self.colour != "blue"{
            self.pickColour(colour: "blue")
        }else{
            self.pickColour(colour: "empty")
        }
    }
    @IBAction func pickPink(_ sender: UIButton) {
        if self.colour != "pink"{
            self.pickColour(colour: "pink")
        }else{
            self.pickColour(colour: "empty")
        }
    }
    @IBAction func pickPurple(_ sender: UIButton) {
        if self.colour != "purple"{
            self.pickColour(colour: "purple")
        }else{
            self.pickColour(colour: "empty")
        }
    }
    
    @IBOutlet weak var colourPicker: UIButton!
}
