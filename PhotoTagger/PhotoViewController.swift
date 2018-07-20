//
//  PhotoViewController.swift
//  PhotoTagger
//
//  Created by Old iMac on 2018-06-20.
//  Copyright © 2018 Scott. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

enum viewState {
    case gallery
    case fit
    case actualSize
}

enum galleryViewMode {
    case all
    case date
    case album
}

class PhotoViewController : UIViewController, UITextViewDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate {
    
    var activeImageArray = [UIImage]()
    var xmpBuilderForFile = [UIImage : XMPBuilder]()
    var activeSelector: UIView?
    var rating = 0
    var colour = ""
    let defaultKeywordText = "Type comma-separated keywords here"
    var imageArray = [[UIImage]]()
    var keyArray = [String]()
    var collectionViewArray = [UICollectionView]()
    var viewType = viewState.gallery
    var galleryView = galleryViewMode.all
    var tempActive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let myStackView = self.view.viewWithTag(1) as! UIStackView
        clearStackView()
        self.view.sendSubview(toBack: myStackView)
        
        self.imageArray = [[UIImage]]()
        self.keyArray = [String]()
        self.collectionViewArray = [UICollectionView]()
        self.xmpBuilderForFile = [UIImage : XMPBuilder]()
        
        grabPhotos()
        if self.galleryView == .all{
            let layout = UICollectionViewFlowLayout()
            let width = 100 as CGFloat
            let height = 150 as CGFloat
            layout.itemSize = CGSize(width: width, height: height)
            let collectionView = UICollectionView(frame: myStackView.bounds, collectionViewLayout: layout)
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "0")
            collectionView.backgroundColor = .white
            myStackView.addArrangedSubview(collectionView)
            
            
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                collectionView.heightAnchor.constraint(equalToConstant: height)
            ])
            collectionView.reloadData()
            self.collectionViewArray.append(collectionView)
        }else{
            for i in 0..<keyArray.count{
                let label = UILabel()
                label.text = keyArray[i]
                label.textAlignment = .left
                label.translatesAutoresizingMaskIntoConstraints = false
                myStackView.addArrangedSubview(label)
                
                let layout = UICollectionViewFlowLayout()
                let width = 100 as CGFloat
                let height = 150 as CGFloat
                layout.itemSize = CGSize(width: width, height: height)
                let newCollectionView = UICollectionView(frame: myStackView.bounds, collectionViewLayout: layout)
                newCollectionView.delegate = self
                newCollectionView.dataSource = self
                newCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: String(i))
                newCollectionView.backgroundColor = .white
                myStackView.addArrangedSubview(newCollectionView)
                
                newCollectionView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newCollectionView.heightAnchor.constraint(equalToConstant: height)
                ])
                newCollectionView.reloadData()
                self.collectionViewArray.append(newCollectionView)
            }
        }
        
        
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinch(sender:)))
        pinch.delegate = self
        imageView.addGestureRecognizer(pinch)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(sender:)))
        pan.delegate = self
        imageView.addGestureRecognizer(pan)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipe(sender:)))
        swipeLeft.direction = .left
        swipeLeft.delegate = self
        imageView.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipe(sender:)))
        swipeRight.direction = .right
        swipeRight.delegate = self
        imageView.addGestureRecognizer(swipeRight)
        
        self.setDataFrom(xmpBuilder: nil)
        /*self.rating = 0
        self.rateStars(stars: 0)
        
        self.colour = "empty"
        self.pickColour(colour: "empty")
        
        applyPlaceHolder(self.view.viewWithTag(14) as! UITextView)*/
        
        createCopyrightAccessoryView(textField: copyrightField)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showCopyRightField))
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(quickAddCopyright))
        tapGesture.numberOfTapsRequired = 1
        copyrightButton.addGestureRecognizer(tapGesture)
        copyrightButton.addGestureRecognizer(longGesture)
        //copyrightButton.setTitleColor(.darkText, for: .normal)
    }
    
    /* Use XMPBuilder is nil for viewType == .gallery
    This will lead to different behaviour*/
    func setDataFrom(xmpBuilder: XMPBuilder?){
        if viewType != .gallery && xmpBuilder != nil{
            if let xmpRating = xmpBuilder!.getStarRating(){
                self.rateStars(stars: xmpRating, force: true)
            }else{
                self.rateStars(stars: 0, force: true)
            }
            if let xmpColour = xmpBuilder!.getColourLabel(){
                self.pickColour(colour: xmpColour, force: true)
            }else{
                self.pickColour(colour: "empty", force: true)
            }
            if let xmpCopyright = xmpBuilder!.getCopyright(){
                copyrightField.text = xmpCopyright
                copyrightButton.setTitleColor(.lightGray, for: .normal)
            }
            if let xmpKeywords = xmpBuilder!.getKeywords(){
                var fieldText = xmpKeywords[0]
                for index in 1..<xmpKeywords.count{
                    fieldText += ", "+xmpKeywords[index]
                }
                applyTypedStyle(self.view.viewWithTag(14) as! UITextView)
                (self.view.viewWithTag(14) as! UITextView).text = fieldText
            }else{
                applyPlaceHolder(self.view.viewWithTag(14) as! UITextView)
            }
        }else if viewType == .gallery{
            if self.activeImageArray.count > 0{
                if let firstBuilder = self.xmpBuilderForFile[self.activeImageArray[0]]{
                    var xmpRating = firstBuilder.getStarRating()
                    var xmpRatingConsistent = true
                    var xmpColour = firstBuilder.getColourLabel()
                    var xmpColourConsistent = true
                    let xmpCopyright = firstBuilder.getCopyright()
                    var xmpCopyrightConsistent = true
                    var xmpKeywords = firstBuilder.getKeywords()
                    for index in 1..<self.activeImageArray.count{
                        if let builder = self.xmpBuilderForFile[self.activeImageArray[index]]{
                            let newRating = builder.getStarRating()
                            if newRating != xmpRating{
                                xmpRatingConsistent = false
                                if newRating != nil && (xmpRating == nil || newRating! > xmpRating!){
                                    xmpRating = newRating
                                }
                            }
                            let newColour = builder.getColourLabel()
                            if newColour != xmpColour{
                                xmpColourConsistent = false
                                xmpColour = nil
                                /*** NEED TO FIND SOME WAY OF DEALING WITH COLOUR INCONSISTENCY ***/
                            }
                            let newCopyright = builder.getCopyright()
                            if newCopyright != xmpCopyright{
                                xmpCopyrightConsistent = false
                                /*** NEED TO FIND SOME WAY OF DEALING WITH COPYRIGHT INCONSISTENCY ***/
                            }
                            if xmpKeywords != nil && xmpKeywords!.count > 0{
                                if let newKeywords = builder.getKeywords(){
                                    var tempArray = [Int]()
                                    for index in 0..<xmpKeywords!.count{
                                        if self.firstIndex(array: newKeywords, item: xmpKeywords![index]) == nil{
                                            tempArray.append(index)
                                        }
                                    }
                                    for index in tempArray{
                                        xmpKeywords!.remove(at: index)
                                    }
                                }
                            }
                        }
                    }
                    let stars : Int
                    if xmpRating == nil{
                        stars = 0
                    }else{
                        stars = xmpRating!
                    }
                    self.rateStars(stars: stars, force: true)
                    if !xmpRatingConsistent{
                        for index in 101..<106{
                            let starView = self.view.viewWithTag(index)
                            if starView is UIButton{
                                (starView as! UIButton).setTitleColor(.lightGray, for: .normal)
                            }
                        }
                    }
                    if xmpColourConsistent{
                        if xmpColour == nil{
                            self.pickColour(colour: "empty", force: true)
                        }else{
                            self.pickColour(colour: xmpColour!, force: true)
                        }
                    }else{
                        /*** NEED TO FIND SOME WAY OF DEALING WITH COLOUR INCONSISTENCY ***/
                        self.pickColour(colour: "empty", force: true)
                    }
                    if xmpCopyrightConsistent && xmpCopyright != nil{
                        copyrightField.text = xmpCopyright
                    }
                    if xmpKeywords != nil && xmpKeywords!.count > 0{
                        var fieldText = xmpKeywords![0]
                        for index in 1..<xmpKeywords!.count{
                            fieldText += ", "+xmpKeywords![index]
                        }
                        applyTypedStyle(self.view.viewWithTag(14) as! UITextView)
                        (self.view.viewWithTag(14) as! UITextView).text = fieldText
                    }else{
                        applyPlaceHolder(self.view.viewWithTag(14) as! UITextView)
                    }
                }else{
                    self.rateStars(stars: 0, force: true)
                    self.pickColour(colour: "empty", force: true)
                    applyPlaceHolder(self.view.viewWithTag(14) as! UITextView)
                }
            }else{
                self.rateStars(stars: 0, force: true)
                self.pickColour(colour: "empty", force: true)
                applyPlaceHolder(self.view.viewWithTag(14) as! UITextView)
            }
            
        }else{
            print("nil xmpBuilder passed to setDataFrom(xmpBuilder:) for non gallery view")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer is UISwipeGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer) || (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UISwipeGestureRecognizer){
            return true
        }else{
            return false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        for i in 0..<self.collectionViewArray.count{
            if collectionView == self.collectionViewArray[i]{
                if i < imageArray.count{
                    count = imageArray[i].count
                }
            }
        }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = UICollectionViewCell()
        
        for i in 0..<self.collectionViewArray.count{
            if collectionView == self.collectionViewArray[i]{
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(i), for: indexPath)
                if firstIndex(array: self.activeImageArray, item: self.imageArray[i][indexPath.row]) != nil{
                    cell.backgroundColor = .lightGray
                }else{
                    cell.backgroundColor = nil
                }
                
                let cellImage = cell.viewWithTag(1) as! UIImageView
                cellImage.image = imageArray[i][indexPath.row]
                
                let height = collectionView.collectionViewLayout.collectionViewContentSize.height
                let oldConstraint = collectionView.constraints[0]
                NSLayoutConstraint.deactivate([oldConstraint])
                NSLayoutConstraint.activate([
                    collectionView.heightAnchor.constraint(equalToConstant: height)
                    ])
                self.view.setNeedsLayout()
                break
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        for i in 0..<self.collectionViewArray.count{
            if collectionView == self.collectionViewArray[i]{
                let index = firstIndex(array: self.activeImageArray, item: imageArray[i][indexPath.row])
                if index != nil{
                    self.activeImageArray.remove(at: index!)
                    print("Removing from active array")
                }else{
                    self.activeImageArray.append(imageArray[i][indexPath.row])
                    print("Adding to active array")
                    self.setDataFrom(xmpBuilder: nil)
                    self.tempActive = false
                }
                collectionView.reloadData()
            }
        }
    }
    
    func firstIndex<T: Equatable>(array: [T], item: T) -> Int?{
        for (index, value) in array.enumerated() {
            if value == item {
                return index
            }
        }
        return nil
    }
    
    func grabPhotos() {
        let imgManager=PHImageManager.default()
        
        let requestOptions=PHImageRequestOptions()
        requestOptions.isSynchronous=true
        requestOptions.deliveryMode = .highQualityFormat
        
        let fetchOptions=PHFetchOptions()
        fetchOptions.sortDescriptors=[NSSortDescriptor(key:"creationDate", ascending: false)]
        
        let fetchResult: PHFetchResult<PHAsset>
        fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        print(fetchResult)
        if fetchResult.count > 0 {
            for i in 0..<fetchResult.count{
                imgManager.requestImage(for: fetchResult.object(at: i) as PHAsset, targetSize: PHImageManagerMaximumSize,contentMode: .aspectFit, options: requestOptions, resultHandler: { (image, error) in
                    self.addImage(image: image!, data: fetchResult.object(at: i))
                })
            }
        }
    }
    
    func addImage(image: UIImage, data: PHAsset){

        data.requestContentEditingInput(with: PHContentEditingInputRequestOptions(), completionHandler: {(input, _) in
            guard let url = input!.fullSizeImageURL else{ return }
            print("found image: ", url)
            self.xmpBuilderForFile.updateValue(XMPBuilder.init(forImageFile: url), forKey: image)
        })
        
        if self.galleryView == .all{
            if self.imageArray.count == 0{
                let newArray = [UIImage]()
                self.imageArray.append(newArray)
            }
            self.imageArray[0].append(image)
        }else if self.galleryView == .date{
            var index = 0
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM dd, YYYY"
            let imageDate = formatter.string(from: data.creationDate!)
            while index < self.imageArray.count{
                if  imageDate == self.keyArray[index]{
                    break
                }
                index += 1
            }
            if index == self.imageArray.count{
                self.keyArray.append(imageDate)
                let newArray = [UIImage]()
                self.imageArray.append(newArray)
            }
            self.imageArray[index].append(image)
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        let touch: UITouch? = touches.first
        if(touch?.view != self.activeSelector){
            self.hideSelector()
        }
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
        if self.activeSelector == self.view.viewWithTag(14){
            let keyboardView = self.activeSelector
            keyboardView?.endEditing(true)
        }
        if self.activeSelector == self.view.viewWithTag(15){
            copyrightField.endEditing(true)
        }
        self.activeSelector?.isHidden = true
        self.activeSelector = nil
        controlBackgroundView.isHidden = true
    }

    
    
    func rateStars(stars: Int, force: Bool){
        var newStars = stars
        if stars == self.rating && !force{
            newStars = 0
        }
        self.rating = newStars
        let starView = self.view.viewWithTag(11)
        var i = 1
        while i <= newStars {
            let button = starView?.viewWithTag(100+i) as! UIButton
            button.setTitle("★", for: .normal)
            button.setTitleColor(.darkText, for: .normal)
            i += 1
        }
        while i <= 5 {
            let button = starView?.viewWithTag(100+i) as! UIButton
            button.setTitle("☆", for: .normal)
            button.setTitleColor(.darkText, for: .normal)
            i += 1
        }
        if !force{
            if self.viewType == .gallery {
                for image in self.activeImageArray{
                    guard let xmpBuilder = self.xmpBuilderForFile[image] else { continue }
                    xmpBuilder.setStarRating(rating: newStars)
                }
            }else{
                guard let xmpBuilder = self.xmpBuilderForFile[imageView.image!] else {return}
                xmpBuilder.setStarRating(rating: newStars)
            }
        }
    }
    @IBAction func starButtonPressed(_ sender: UIButton) {
        let starButtonSelectors = self.view.viewWithTag(11)
        if starButtonSelectors!.isHidden{
            self.hideSelector()
            starButtonSelectors!.isHidden = false
            controlBackgroundView.isHidden = false
            self.activeSelector = starButtonSelectors
        }else{
            self.hideSelector()
        }
    }
    
    
    
    @IBAction func rated1Star(_ sender: UIButton) {
        self.rateStars(stars: 1, force: false)
    }
    @IBAction func rated2Star(_ sender: UIButton) {
        self.rateStars(stars: 2, force: false)
    }
    @IBAction func rated3Star(_ sender: UIButton) {
        self.rateStars(stars: 3, force: false)
    }
    @IBAction func rated4Star(_ sender: UIButton) {
        self.rateStars(stars: 4, force: false)
    }
    @IBAction func rated5Star(_ sender: UIButton) {
        self.rateStars(stars: 5, force: false)
    }
    
    
    
    @IBAction func openColourPicker(_ sender: UIButton) {
        let colourButtons = self.view.viewWithTag(12)
        if colourButtons!.isHidden{
            self.hideSelector()
            colourButtons!.isHidden = false
            controlBackgroundView.isHidden = false
            self.activeSelector = colourButtons
        }else{
            self.hideSelector()
        }
    }
    func pickColour(colour: String, force: Bool) {
        var newColour = colour
        if colour == self.colour && !force{
            newColour = "empty"
        }
        
        self.colour = newColour
        let fileString = newColour + "_square"
        let colourImage = UIImage(named: fileString)?.withRenderingMode(.alwaysOriginal)
        colourPicker.setImage(colourImage, for: UIControlState.normal)
        if !force{
            if self.viewType == .gallery{
                for image in self.activeImageArray{
                    guard let xmpBuilder = self.xmpBuilderForFile[image] else { continue }
                    xmpBuilder.setColourLabel(colour: newColour)
                }
            }else{
                guard let xmpBuilder = self.xmpBuilderForFile[imageView.image!] else {return}
                xmpBuilder.setColourLabel(colour: newColour)
            }
        }
    }
    
    

    @IBAction func pickRed(_ sender: UIButton) {
        self.pickColour(colour: "red", force: false)
    }
    @IBAction func pickOrange(_ sender: UIButton) {
        self.pickColour(colour: "orange", force: false)
    }
    @IBAction func pickYellow(_ sender: UIButton) {
        self.pickColour(colour: "yellow", force: false)
    }
    @IBAction func pickGreen(_ sender: UIButton) {
        self.pickColour(colour: "green", force: false)
    }
    @IBAction func pickBlue(_ sender: UIButton) {
        self.pickColour(colour: "blue", force: false)
    }
    @IBAction func pickPink(_ sender: UIButton) {
        self.pickColour(colour: "pink", force: false)
    }
    @IBAction func pickPurple(_ sender: UIButton) {
        self.pickColour(colour: "purple", force: false)
    }
    
    @IBOutlet weak var colourPicker: UIButton!
    
    
    
    @IBAction func showKeywordField(_ sender: UIButton) {
        let keywordField = self.view.viewWithTag(14)
        if keywordField!.isHidden{
            self.hideSelector()
            keywordField!.isHidden = false
            controlBackgroundView.isHidden = false
            self.activeSelector = keywordField
        }else{
            self.hideSelector()
        }
    }
    func applyPlaceHolder(_ textView: UITextView){
        textView.text = self.defaultKeywordText
        textView.textColor = UIColor.lightGray
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
        if textView == self.view.viewWithTag(14) && textView.text == self.defaultKeywordText{
            moveCursortoStart(textView)
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == self.view.viewWithTag(14){
            let textToSubmit : String?
            if textView.text == self.defaultKeywordText{
                textToSubmit = nil
            }else{
                textToSubmit = textView.text
            }
            if self.viewType == .gallery{
                for image in self.activeImageArray{
                    guard let xmpBuilder = self.xmpBuilderForFile[image] else{ continue }
                    xmpBuilder.setKeywords(words: textToSubmit)
                }
            }else{
                guard let xmpBuilder = self.xmpBuilderForFile[imageView.image!] else{ return }
                xmpBuilder.setKeywords(words: textToSubmit)
            }
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
        let copyRightStack = self.view.viewWithTag(15)!
        if copyRightStack.isHidden{
            self.hideSelector()
            copyRightStack.isHidden = false
            controlBackgroundView.isHidden = false
            self.activeSelector = copyRightStack
        }else{
            if copyrightButton.titleColor(for: .normal) == .darkText{
                self.addCopyright()
                self.hideSelector()
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
        if self.viewType == .gallery{
            for image in self.activeImageArray{
                guard let xmpBuilder = self.xmpBuilderForFile[image] else { continue }
                xmpBuilder.setCopyright(copy: copyrightField.text)
            }
        }else{
            guard let xmpBuilder = self.xmpBuilderForFile[imageView.image!] else{return}
            xmpBuilder.setCopyright(copy: copyrightField.text)
        }
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
        self.hideSelector()
    }
    
    
    
    @IBAction func showViewOptions(_ sender: UIButton) {
        let viewOptionStack = self.view.viewWithTag(16)!
        if viewOptionStack.isHidden{
            self.hideSelector()
            viewOptionStack.isHidden = false
            controlBackgroundView.isHidden = false
            self.activeSelector = viewOptionStack
        }else{
            self.hideSelector()
        }
    }
    @IBAction func setViewToGallery(_ sender: UIButton) {
        print("gallery")
        self.view.viewWithTag(20)!.isHidden = true
        let thumbImage = UIImage(named: "thumbs")?.withRenderingMode(.alwaysOriginal)
        viewOptionButton.setImage(thumbImage, for: .normal)
        if self.tempActive{
            self.activeImageArray.removeAll()
        }
        self.hideSelector()
        self.viewSelector.isHidden = false
        self.viewType = .gallery
        self.setDataFrom(xmpBuilder: nil)
    }
    @IBAction func setViewToFit(_ sender: UIButton) {
        print("fit")
        let oldType = self.viewType
        self.viewType = .fit
        let imageViewHolder = self.view.viewWithTag(20)
        imageView.transform = CGAffineTransform.identity
        if oldType == .gallery{
            if self.activeImageArray.count == 0{
                for i in 0..<self.imageArray.count{
                    self.activeImageArray.append(contentsOf: self.imageArray[i])
                }
                self.tempActive = true
            }
            if(self.activeImageArray.count == 0){
                return
            }
            imageView.image = self.activeImageArray[0]
            if let builder = xmpBuilderForFile[imageView.image!]{
                self.setDataFrom(xmpBuilder: builder)
            }else{
                print("xmpBuilder not found for image.")
            }
            self.viewSelector.isHidden = true
            imageViewHolder!.isHidden = false
        }
        let fitImage = UIImage(named: "fit")?.withRenderingMode(.alwaysOriginal)
        viewOptionButton.setImage(fitImage, for: .normal)
        imageView.contentMode = .scaleAspectFit
        self.hideSelector()
    }
    @IBAction func setViewToActualSize(_ sender: UIButton) {
        print("actual")
        let oldType = self.viewType
        self.viewType = .actualSize
        let imageViewHolder = self.view.viewWithTag(20)
        imageView.transform = CGAffineTransform.identity
        if oldType == .gallery{
            if self.activeImageArray.count == 0{
                for i in 0..<self.imageArray.count{
                    self.activeImageArray.append(contentsOf: self.imageArray[i])
                }
                self.tempActive = true
            }
            imageView.image = self.activeImageArray[0]
            if let builder = xmpBuilderForFile[imageView.image!]{
                self.setDataFrom(xmpBuilder: builder)
            }else{
                print("xmpBuilder not found for image.")
            }
            self.viewSelector.isHidden = true
            imageViewHolder!.isHidden = false
        }
        let actualImage = UIImage(named: "100percent")?.withRenderingMode(.alwaysOriginal)
        viewOptionButton.setImage(actualImage, for: .normal)
        imageView.contentMode = .scaleAspectFit
        let scaleAdjustment: CGFloat
        guard let image = imageView.image else{return}
        let imageFrame = AVMakeRect(aspectRatio: image.size, insideRect: imageView.frame)
        if imageFrame.minX - imageView.frame.minX < imageFrame.minY - imageView.frame.minY{
            print("landscape")
            scaleAdjustment = (image.size.width*image.scale)/(imageView.frame.width*UIScreen.main.scale)
        }else{
            print("portrait")
            scaleAdjustment = (image.size.height*image.scale)/(imageView.frame.height*UIScreen.main.scale)
        }
        print("scaleAdjustment: ", scaleAdjustment)
        imageView.transform = imageView.transform.scaledBy(x: scaleAdjustment, y: scaleAdjustment)
        self.hideSelector()
    }
    
    @objc func swipe(sender: UISwipeGestureRecognizer){
        guard let activeImageIndex = firstIndex(array: self.activeImageArray, item: imageView.image!)else{return}
        if sender.direction == .right && activeImageIndex > 0{
            imageView.image = self.activeImageArray[activeImageIndex-1]
            if let builder = xmpBuilderForFile[imageView.image!]{
                self.setDataFrom(xmpBuilder: builder)
            }else{
                print("xmpBuilder not found for image.")
            }
        }else if sender.direction == .left && activeImageIndex < activeImageArray.count-1{
            imageView.image = self.activeImageArray[activeImageIndex+1]
            if let builder = xmpBuilderForFile[imageView.image!]{
                self.setDataFrom(xmpBuilder: builder)
            }else{
                print("xmpBuilder not found for image.")
            }
        }
        if self.viewType == .fit{
            setViewToFit(viewOptionButton)
        }else if self.viewType == .actualSize{
            setViewToActualSize(viewOptionButton)
        }
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer){
        if sender.state == .changed {
            let pinchCenter = CGPoint(x: sender.location(in: imageView).x - imageView.bounds.midX,
                                      y: sender.location(in: imageView).y - imageView.bounds.midY)
            let transform = imageView.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            imageView.transform = transform
            let translation = correctImageToBounds(imageView: imageView, translation: nil)
            imageView.transform = imageView.transform.translatedBy(x: translation.x, y: translation.y)
            sender.scale = 1
        }
    }
    @objc func pan(sender: UIPanGestureRecognizer){
        guard let containerView = self.view.viewWithTag(20) else {return}
        var translation = sender.translation(in: containerView)
        
        translation = correctImageToBounds(imageView: imageView, translation: translation)
        
        imageView.transform = imageView.transform.translatedBy(x: translation.x, y: translation.y)
        
        sender.setTranslation(CGPoint.zero, in: containerView)
    }
    func correctImageToBounds(imageView: UIImageView, translation: CGPoint?) -> CGPoint{
        var finalTranslation : CGPoint
        if translation == nil{
            finalTranslation = CGPoint(x: 0, y: 0)
        }else{
            finalTranslation = translation!
        }
        let imageFrame = AVMakeRect(aspectRatio: imageView.image!.size, insideRect: imageView.frame)
        
        let leftSpace = imageFrame.minX - imageView.frame.minX
        let rightSpace = imageView.frame.maxX - imageFrame.maxX
        if imageFrame.width > imageView.bounds.width{
            if imageView.bounds.minX < imageView.frame.minX + leftSpace + finalTranslation.x{
                finalTranslation.x = imageView.bounds.minX - imageView.frame.minX - leftSpace
            }else if imageView.bounds.maxX > imageView.frame.maxX - rightSpace + finalTranslation.x{
                finalTranslation.x = imageView.bounds.maxX - imageView.frame.maxX + rightSpace
            }
        }else{
            if imageView.frame.minX + leftSpace + finalTranslation.x < imageView.bounds.minX{
                finalTranslation.x = imageView.bounds.minX - imageView.frame.minX - leftSpace
            }else if imageView.frame.maxX - rightSpace + finalTranslation.x > imageView.bounds.maxX{
                finalTranslation.x = imageView.bounds.maxX - imageView.frame.maxX + rightSpace
            }
        }
        let topSpace = imageFrame.minY - imageView.frame.minY
        let bottomSpace = imageView.frame.maxY - imageFrame.maxY
        if imageFrame.height > imageView.bounds.height{
            if imageView.bounds.minY < imageView.frame.minY + topSpace + finalTranslation.y{
                finalTranslation.y = imageView.bounds.minY - imageView.frame.minY - topSpace
            }else if imageView.bounds.maxY > imageView.frame.maxY - bottomSpace + finalTranslation.y{
                finalTranslation.y = imageView.bounds.maxY - imageView.frame.maxY + bottomSpace
            }
        }else{
            if imageView.frame.minY + topSpace + finalTranslation.y < imageView.bounds.minY{
                finalTranslation.y = imageView.bounds.minY - imageView.frame.minY - topSpace
            }else if imageView.frame.maxY - bottomSpace + finalTranslation.y > imageView.bounds.maxY{
                finalTranslation.y = imageView.bounds.maxY - imageView.frame.maxY + bottomSpace
            }
        }
        return finalTranslation
    }
    
    @IBAction func galleryViewSelect(_ sender: UIButton) {
        if sender == self.allGalleryButton && self.galleryView != .all{
            self.galleryView = .all
            self.allGalleryButton.isHighlighted = true
            self.dateGalleryButton.isHighlighted = false
            self.viewDidLoad()
        }else if sender == dateGalleryButton && self.galleryView != .date{
            self.galleryView = .date
            self.allGalleryButton.isHighlighted = false
            self.dateGalleryButton.isHighlighted = true
            self.viewDidLoad()
        }
    }
    func clearStackView(){
        let myStackView = self.view.viewWithTag(1) as! UIStackView
        for v in myStackView.subviews {
            v.removeFromSuperview()
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var allGalleryButton: UIButton!
    @IBOutlet weak var dateGalleryButton: UIButton!
    @IBOutlet weak var viewSelector: UIView!
    @IBOutlet weak var copyrightButton: UIButton!
    @IBOutlet weak var viewOptionButton: UIButton!
    @IBOutlet weak var copyrightField: UITextField!
    @IBOutlet weak var controlBackgroundView: UIView!
}

class PhotoCell: UICollectionViewCell {
    var imageView = UIImageView()
    var bottomView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true
        self.imageView.tag = 1
        
        self.addSubview(self.imageView)
        self.addSubview(self.bottomView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.bottomView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.imageView.topAnchor.constraint(equalTo: self.topAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.bottomView.topAnchor),
            self.bottomView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.bottomView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.bottomView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.bottomView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
