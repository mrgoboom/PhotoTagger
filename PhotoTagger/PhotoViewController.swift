//
//  PhotoViewController.swift
//  PhotoTagger
//
//  Created by Old iMac on 2018-06-20.
//  Copyright © 2018 Scott. All rights reserved.
//

import UIKit

class PhotoViewController : UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    var imageArray: [UIImage]?
    var activeImage: UIImage?
    var activeSelector: UIView?
    var rating = 0
    var colour = ""
    let defaultKeywordText = "Type comma-separated keywords here"
    var textViewText = ""
        
    override func viewDidLoad() {
        super.viewDidLoad()
        let imageView = self.view.viewWithTag(3) as! UIImageView
        self.activeImage = imageView.image
        
        self.rating = 0
        self.rateStars(stars: 0)
        
        self.colour = "empty"
        self.pickColour(colour: "empty")
        
        applyPlaceHolder(self.view.viewWithTag(4) as! UITextView)
        
        createCopyrightAccessoryView(textField: copyrightField)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showCopyRightField))
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(quickAddCopyright))
        tapGesture.numberOfTapsRequired = 1
        copyrightButton.addGestureRecognizer(tapGesture)
        copyrightButton.addGestureRecognizer(longGesture)
        copyrightButton.setTitleColor(.darkText, for: .normal)
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
  
    func createCopyrightAccessoryView(textField: UITextField){
        let copyrightButton = UIButton(type: .custom)
        copyrightButton.setTitle("©", for: .normal)
        copyrightButton.addTarget(self, action: #selector(addCopyrightSymbol), for: .touchUpInside)
        copyrightButton.translatesAutoresizingMaskIntoConstraints = false
        copyrightButton.isEnabled = true
        copyrightButton.showsTouchWhenHighlighted = true
        
        let registeredButton = UIButton(type: .custom)
        registeredButton.setTitle("®", for: .normal)
        registeredButton.addTarget(self, action: #selector(addRegisteredSymbol), for: .touchUpInside)
        registeredButton.translatesAutoresizingMaskIntoConstraints = false
        registeredButton.isEnabled = true
        registeredButton.showsTouchWhenHighlighted = true
        
        let buttonBar = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 45))
        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        buttonBar.backgroundColor = .lightGray
        
        buttonBar.addSubview(copyrightButton)
        buttonBar.addSubview(registeredButton)
        
        textField.inputAccessoryView = buttonBar
        
        NSLayoutConstraint.activate([
            copyrightButton.trailingAnchor.constraint(equalTo: buttonBar.centerXAnchor, constant: -40),
            copyrightButton.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor),
            
            registeredButton.leadingAnchor.constraint(equalTo: buttonBar.centerXAnchor, constant: 40),
            registeredButton.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor)
        ])
    }
    @objc func addCopyrightSymbol(sender: UIButton!) {
        if copyrightField.text != nil && copyrightField.text != ""{
            copyrightField.text = copyrightField.text! + "©"
        }else{
            copyrightField.text = "©"
        }
    }
    @objc func addRegisteredSymbol(sender: UIButton!) {
        if copyrightField.text != nil && copyrightField.text != ""{
            copyrightField.text = copyrightField.text! + "®"
        }else{
            copyrightField.text = "®"
        }
    }
    
    func hideSelector(){
        if self.activeSelector == self.view.viewWithTag(4){
            let keyboardView = self.activeSelector
            keyboardView?.endEditing(true)
        }
        if self.activeSelector == self.view.viewWithTag(5){
            copyrightField.endEditing(true)
        }
        self.activeSelector?.isHidden = true
        self.activeSelector = nil
    }

    
    
    func rateStars(stars: Int){
        var newStars = stars
        if stars == self.rating{
            newStars = 0
        }
        self.rating = newStars
        let starView = self.view.viewWithTag(1)
        var i = 1
        while i <= newStars {
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
        self.rateStars(stars: 1)
    }
    @IBAction func rated2Star(_ sender: UIButton) {
        self.rateStars(stars: 2)
    }
    @IBAction func rated3Star(_ sender: UIButton) {
        self.rateStars(stars: 3)
    }
    @IBAction func rated4Star(_ sender: UIButton) {
        self.rateStars(stars: 4)
    }
    @IBAction func rated5Star(_ sender: UIButton) {
        self.rateStars(stars: 5)
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
        var newColour = colour
        if colour == self.colour{
            newColour = "empty"
        }
        
        self.colour = newColour
        let fileString = newColour + "_square"
        let colourImage = UIImage(named: fileString)?.withRenderingMode(.alwaysOriginal)
        colourPicker.setImage(colourImage, for: UIControlState.normal)
    }
    
    

    @IBAction func pickRed(_ sender: UIButton) {
        self.pickColour(colour: "red")
    }
    @IBAction func pickOrange(_ sender: UIButton) {
        self.pickColour(colour: "orange")
    }
    @IBAction func pickYellow(_ sender: UIButton) {
        self.pickColour(colour: "yellow")
    }
    @IBAction func pickGreen(_ sender: UIButton) {
        self.pickColour(colour: "green")
    }
    @IBAction func pickBlue(_ sender: UIButton) {
        self.pickColour(colour: "blue")
    }
    @IBAction func pickPink(_ sender: UIButton) {
        self.pickColour(colour: "pink")
    }
    @IBAction func pickPurple(_ sender: UIButton) {
        self.pickColour(colour: "purple")
    }
    
    @IBOutlet weak var colourPicker: UIButton!
    
    
    
    @IBAction func showKeywordField(_ sender: UIButton) {
        let keywordField = self.view.viewWithTag(4)
        if keywordField!.isHidden{
            self.hideSelector()
            keywordField!.isHidden = false
            self.activeSelector = keywordField
        }else{
            self.hideSelector()
        }
    }
    func applyPlaceHolder(_ textView: UITextView){
        textView.text = defaultKeywordText
        textView.textColor = UIColor.lightGray
        textViewText = defaultKeywordText
    }
    func applyTypedStyle(_ textView: UITextView){
        textView.textColor = UIColor.darkText
    }
    func moveCursortoStart(_ textView: UITextView){
        DispatchQueue.main.async {
            textView.selectedRange = NSMakeRange(0, 0)
        }
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == self.view.viewWithTag(4) && textView.text == self.defaultKeywordText{
            moveCursortoStart(textView)
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newLength = textView.text.count + text.count - range.length
        if newLength > 0{
            if textView.text == defaultKeywordText{
                if text.count == 0{
                    return false
                }
                applyTypedStyle(textView)
                textView.text = ""
            }
            return true
        }else{
            applyPlaceHolder(textView)
            moveCursortoStart(textView)
            return false
        }
    }
    
    
    
    @objc func showCopyRightField(){
        let copyRightStack = self.view.viewWithTag(5)!
        if copyRightStack.isHidden{
            self.hideSelector()
            copyRightStack.isHidden = false
            self.activeSelector = copyRightStack
        }else{
            if copyrightButton.titleColor(for: .normal) == .darkText{
                self.addCopyright()
            }else{
                self.hideSelector()
            }
        }
    }
    @objc func quickAddCopyright(sender: UIGestureRecognizer){
        if sender.state == .ended && copyrightButton.titleColor(for: .normal) == .darkText{
            self.addCopyright()
        }
    }
    func addCopyright(){
        copyrightButton.setTitleColor(.lightGray, for: .normal)
        print("Apply Copyright")
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count != 0 || range.length != 0{
            copyrightButton.setTitleColor(.darkText, for: .normal)
        }
        return true
    }
    @IBAction func applyCopyrightButton(_ sender: UIButton) {
        self.addCopyright()
    }
    
    @IBOutlet weak var copyrightButton: UIButton!
    @IBOutlet weak var copyrightField: UITextField!
}
