//
//  ViewController.swift
//  PhotoTagger
//
//  Created by Scott on 2018-01-25.
//  Copyright © 2018 Scott. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var imageArray = [[UIImage]]()
    var momentArray = [PHAssetCollection]()
    var collectionViewArray = [UICollectionView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let myStackView = self.view.viewWithTag(1) as! UIStackView
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
                let side = 100 as CGFloat
                layout.itemSize = CGSize(width: side, height: side)
                let newCollectionView = UICollectionView(frame: myStackView.bounds, collectionViewLayout: layout)
                newCollectionView.delegate = self
                newCollectionView.dataSource = self
                newCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: String(self.collectionViewArray.count))
                newCollectionView.backgroundColor = UIColor.white
                myStackView.addArrangedSubview(newCollectionView)
                
                newCollectionView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newCollectionView.heightAnchor.constraint(equalToConstant: side)
                ])
                newCollectionView.reloadData()
                
                self.collectionViewArray.append(newCollectionView)
            }
            //print(myStackView.arrangedSubviews)
            //print()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        for i in 0..<self.collectionViewArray.count{
            if collectionView == self.collectionViewArray[i]{
                count = imageArray[i].count
                print(count, " items in collectionview ", i)
                print()
            }
        }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = UICollectionViewCell()
        
        for i in 0..<self.collectionViewArray.count{
            if collectionView == self.collectionViewArray[i]{
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(i), for: indexPath)
                
                let imageView = cell.viewWithTag(1) as! UIImageView
                imageView.image = imageArray[i][indexPath.row]
                
                let height = collectionView.collectionViewLayout.collectionViewContentSize.height
                print("height of collection view ", i, " is ", height)
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
                let imageController = storyboard?.instantiateViewController(withIdentifier: "ImageViewer") as! PhotoViewController?
                let imageView = imageController?.view.viewWithTag(3) as! UIImageView
                imageView.image = imageArray[i][indexPath.row]
                imageController?.setImageArray(images: imageArray[i])
                self.navigationController?.pushViewController(imageController!, animated: true)
            }
        }
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
    
    func grabPhotos(moment: PHAssetCollection) {
        let imgManager=PHImageManager.default()
        
        let requestOptions=PHImageRequestOptions()
        requestOptions.isSynchronous=true
        requestOptions.deliveryMode = .highQualityFormat
        
        let fetchOptions=PHFetchOptions()
        fetchOptions.sortDescriptors=[NSSortDescriptor(key:"creationDate", ascending: false)]
        
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(in: moment, options: fetchOptions)
        print(fetchResult)
        if fetchResult.count > 0 {
            for i in 0..<fetchResult.count{
                imgManager.requestImage(for: fetchResult.object(at: i) as PHAsset, targetSize: PHImageManagerMaximumSize,contentMode: .aspectFit, options: requestOptions, resultHandler: { (image, error) in
                    self.addImage(image: image!, moment: moment)
                })
            }
        }
    }
    
    func addImage(image: UIImage, moment: PHAssetCollection){
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, YYYY"
        let momentDate = formatter.string(from: moment.startDate!)
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
    }
}

class PhotoCell: UICollectionViewCell {
    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true
        self.imageView.tag = 1
        self.addSubview(self.imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
