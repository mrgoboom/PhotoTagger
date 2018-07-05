//
//  PhotoViewController.swift
//  PhotoTagger
//
//  Created by Old iMac on 2018-06-20.
//  Copyright © 2018 Scott. All rights reserved.
//

import UIKit
import Photos

enum viewState {
    case gallery
    case fit
    case actualSize
}

class PhotoViewController : UIViewController, UITextViewDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var activeImageArray = [UIImage]()
    var activeSelector: UIView?
    var rating = 0
    var colour = ""
    let defaultKeywordText = "Type comma-separated keywords here"
    var textViewText = ""
    var imageArray = [[UIImage]]()
    var momentArray = [PHAssetCollection]()
    var collectionViewArray = [UICollectionView]()
    var viewType = viewState.gallery
    var tempActive = false
    var isZooming = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewType = .gallery
        let myStackView = self.view.viewWithTag(1) as! UIStackView
        self.view.sendSubview(toBack: myStackView)
        
        
        /* Sort by moments: Currently has issues when video present
        grabMoments()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, YYYY"
        var lastLabel = ""
        for index in 0..<self.momentArray.count{
            let moment = momentArray[index]
            grabPhotos(moment: moment)
            let newLabel = formatter.string(from: moment.startDate!)
            if newLabel != lastLabel{
                lastLabel = newLabel
                let label = UILabel()
                label.text = newLabel
                label.textAlignment = NSTextAlignment.left
                label.translatesAutoresizingMaskIntoConstraints = false
                myStackView.addArrangedSubview(label)
                
                let layout = UICollectionViewFlowLayout()
                let width = 100 as CGFloat
                let height = 150 as CGFloat
                layout.itemSize = CGSize(width: width, height: height)
                let newCollectionView = UICollectionView(frame: myStackView.bounds, collectionViewLayout: layout)
                newCollectionView.delegate = self
                newCollectionView.dataSource = self
                newCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: String(self.collectionViewArray.count))
                newCollectionView.backgroundColor = UIColor.white
                myStackView.addArrangedSubview(newCollectionView)
                
                newCollectionView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newCollectionView.heightAnchor.constraint(equalToConstant: height)
                ])
                newCollectionView.reloadData()
                
                self.collectionViewArray.append(newCollectionView)
            }
            //print(myStackView.arrangedSubviews)
            //print()
        }
        */
        /* Just grabs all photos */
        grabPhotos(moment: nil)
        let layout = UICollectionViewFlowLayout()
        let width = 100 as CGFloat
        let height = 150 as CGFloat
        layout.itemSize = CGSize(width: width, height: height)
        let collectionView = UICollectionView(frame: myStackView.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "0")
        collectionView.backgroundColor = UIColor.white
        myStackView.addArrangedSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: height)
        ])
        collectionView.reloadData()
        self.collectionViewArray.append(collectionView)
        
        
        
        
        let imageView = self.view.viewWithTag(13) as! UIImageView
        imageView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinch(sender:))))
        
        
        self.rating = 0
        self.rateStars(stars: 0)
        
        self.colour = "empty"
        self.pickColour(colour: "empty")
        
        applyPlaceHolder(self.view.viewWithTag(14) as! UITextView)
        
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
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        for i in 0..<self.collectionViewArray.count{
            if collectionView == self.collectionViewArray[i]{
                if i < imageArray.count{
                    count = imageArray[i].count
                }
                //print(count, " items in collectionview ", i)
                //print()
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
                
                let imageView = cell.viewWithTag(1) as! UIImageView
                imageView.image = imageArray[i][indexPath.row]
                
                let height = collectionView.collectionViewLayout.collectionViewContentSize.height
                //print("height of collection view ", i, " is ", height)
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
    
    func grabMoments(){
        let fetchOptions=PHFetchOptions()
        fetchOptions.sortDescriptors=[NSSortDescriptor(key:"startDate", ascending: false)]
        
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.moment, subtype: PHAssetCollectionSubtype.any, options: fetchOptions)
        for i in 0..<fetchResult.count {
            let resObj = fetchResult.object(at: i)
            print(resObj.startDate!)
            self.momentArray.append(resObj)
        }
    }
    
    func grabPhotos(moment: PHAssetCollection?) {
        let imgManager=PHImageManager.default()
        
        let requestOptions=PHImageRequestOptions()
        requestOptions.isSynchronous=true
        requestOptions.deliveryMode = .highQualityFormat
        
        let fetchOptions=PHFetchOptions()
        fetchOptions.sortDescriptors=[NSSortDescriptor(key:"creationDate", ascending: false)]
        
        let fetchResult: PHFetchResult<PHAsset>
        if moment != nil{
            fetchResult = PHAsset.fetchAssets(in: moment!, options: fetchOptions)
        }else{
            fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        }
        print(fetchResult)
        if fetchResult.count > 0 {
            for i in 0..<fetchResult.count{
                imgManager.requestImage(for: fetchResult.object(at: i) as PHAsset, targetSize: PHImageManagerMaximumSize,contentMode: .aspectFit, options: requestOptions, resultHandler: { (image, error) in
                    self.addImage(image: image!, moment: moment)
                })
            }
        }
    }
    
    func addImage(image: UIImage, moment: PHAssetCollection?){
        if moment != nil{
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM dd, YYYY"
            let momentDate = formatter.string(from: moment!.startDate!)
            var index = 0
            var lastMoment = ""
            for m in self.momentArray{
                let thisMoment = formatter.string(from: m.startDate!)
                if momentDate == thisMoment{
                    break
                }else if thisMoment != lastMoment{
                    index += 1
                    lastMoment = thisMoment
                }
            }
            if index < imageArray.count{
                self.imageArray[index].append(image)
            }else{
                var newArray = [UIImage]()
                newArray.append(image)
                self.imageArray.append(newArray)
            }
        }else{
            if self.imageArray.count == 0{
                let newArray = [UIImage]()
                imageArray.append(newArray)
            }
            imageArray[0].append(image)
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
    }

    
    
    func rateStars(stars: Int){
        var newStars = stars
        if stars == self.rating{
            newStars = 0
        }
        self.rating = newStars
        let starView = self.view.viewWithTag(11)
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
        let starButtonSelectors = self.view.viewWithTag(11)
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
        let colourButtons = self.view.viewWithTag(12)
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
        let keywordField = self.view.viewWithTag(14)
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
        if textView == self.view.viewWithTag(14) && textView.text == self.defaultKeywordText{
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
        let copyRightStack = self.view.viewWithTag(15)!
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
    
    
    
    @IBAction func showViewOptions(_ sender: UIButton) {
        let viewOptionStack = self.view.viewWithTag(16)!
        if viewOptionStack.isHidden{
            self.hideSelector()
            viewOptionStack.isHidden = false
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
        self.viewType = .gallery
    }
    @IBAction func setViewToFit(_ sender: UIButton) {
        print("fit")
        let imageView = self.view.viewWithTag(13) as! UIImageView
        let imageViewHolder = self.view.viewWithTag(20)
        if self.viewType == .gallery{
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
            imageViewHolder!.isHidden = false
        }
        let fitImage = UIImage(named: "fit")?.withRenderingMode(.alwaysOriginal)
        viewOptionButton.setImage(fitImage, for: .normal)
        imageView.contentMode = .scaleAspectFit
        self.viewType = .fit
        self.isZooming = false
        self.hideSelector()
    }
    @IBAction func setViewToActualSize(_ sender: UIButton) {
        print("actual")
        let imageView = self.view.viewWithTag(13) as! UIImageView
        let imageViewHolder = self.view.viewWithTag(20)
        if self.viewType == .gallery{
            if self.activeImageArray.count == 0{
                for i in 0..<self.imageArray.count{
                    self.activeImageArray.append(contentsOf: self.imageArray[i])
                }
                self.tempActive = true
            }
            imageView.image = self.activeImageArray[0]
            imageViewHolder!.isHidden = false
        }
        let actualImage = UIImage(named: "100percent")?.withRenderingMode(.alwaysOriginal)
        viewOptionButton.setImage(actualImage, for: .normal)
        imageView.contentMode = .center
        self.viewType = .actualSize
        self.isZooming = true
        self.hideSelector()
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer){
        print("pinch")
        let imageView = self.view.viewWithTag(13) as! UIImageView
        if sender.state == .began {
            let currentScale = imageView.frame.size.width / imageView.bounds.size.width
            let newScale = currentScale*sender.scale
            if newScale > 1 {
                self.isZooming = true
            }
        } else if sender.state == .changed {
            guard let view = sender.view else {return}
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            /*let currentScale = imageView.frame.size.width / imageView.bounds.size.width
            var newScale = currentScale*sender.scale
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                imageView.transform = transform
                sender.scale = 1
            }else {*/
            view.transform = transform
            sender.scale = 1
            //}
        }/* else if sender.state == .ended {
            UIView.animate(withDuration: 0.3, animations: {
                imageView.transform = CGAffineTransform.identity
            }, completion: { _ in
                self.isZooming = false
            })
        }*/
    }
    
    @IBOutlet weak var copyrightButton: UIButton!
    @IBOutlet weak var viewOptionButton: UIButton!
    @IBOutlet weak var copyrightField: UITextField!
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
