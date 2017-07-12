//
//  ImagesCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Duy Le on 6/30/17.
//  Copyright © 2017 Andrew Le. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "AddImageCollectionCell"

class AddImagesCollectionViewController: UICollectionViewController {
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    

    var imageIndex = Int()
    var annotation = ImageAnnotation()
    static var downloadingImageComplete = true
    private let delegate = UIApplication.shared.delegate as! AppDelegate
    static var imageUrlArr = [String]()
    
    var annotationCoreData : Annotation! = nil
    
    var timer = Timer()
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.hidesBackButton = true
        fireTimerCheckingDownloadStatus()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
        
        let space = 2
        let itemSize = (Double(view.frame.width) - (Double(space) * 2))/3
        flowLayout.itemSize = CGSize(width: itemSize, height: itemSize)
        flowLayout.minimumInteritemSpacing = CGFloat(space)
        flowLayout.minimumLineSpacing = CGFloat(space)
    }
    
    
    private func fireTimerCheckingDownloadStatus(){
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(AddImagesCollectionViewController.checkingImageDownload),userInfo: nil, repeats: true)
        timer.fire()
    }
    
    func checkingImageDownload() {
        let latitude = Float(annotation.coordinate.latitude)
        let longitude = Float(annotation.coordinate.longitude)

        if AddImagesCollectionViewController.downloadingImageComplete {
            navigationItem.hidesBackButton = false
            
            let annotationArr = (delegate.fetchedResultsController.fetchedObjects as? [Annotation])!
            for temp in annotationArr {
                if temp.latitude == latitude && temp.longitude == longitude {
                    if((temp.images?.count)! > 0 ){
                        annotationCoreData = temp
                        timer.invalidate()
                    }
                }
            }
        }
        else {
            print("check")
            collectionView?.reloadData()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if annotationCoreData == nil && AddImagesCollectionViewController.imageUrlArr.count < 30{
            return 30
        }
        if annotationCoreData != nil {
            return (annotationCoreData.images?.count)!
        }
        return AddImagesCollectionViewController.imageUrlArr.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? AddImageCollectionViewCell
        
        cell?.activityIndicator.isHidden = false
        cell?.activityIndicator.startAnimating()
        if AddImagesCollectionViewController.imageUrlArr.count > 0 {
            downloadImage(imagePath: AddImagesCollectionViewController.imageUrlArr[indexPath.row], completionHandler: { (imageData, error) in
                if error == nil {
                    cell?.imageView.image =  UIImage(data: imageData!)
                    cell?.activityIndicator.isHidden = true
                }
            })
            
        }
        else if (annotationCoreData.images?.count)! > 0  {
            let imageDataArr = annotationCoreData.images?.allObjects as? [Image]
            if let imageData = imageDataArr?[indexPath.row].image {
                cell?.imageView.image =  UIImage(data: imageData as Data)
            }
            cell?.activityIndicator.isHidden = true
        }
        return cell!
    }
    
    func downloadImage( imagePath:String, completionHandler: @escaping (_ imageData: Data?, _ errorString: String?) -> Void){
        let session = URLSession.shared
        let imgURL = NSURL(string: imagePath)
        let request: NSURLRequest = NSURLRequest(url: imgURL! as URL)
        
        let task = session.dataTask(with: request as URLRequest) {data, response, downloadError in
            
            if downloadError != nil {
                completionHandler(nil, "Could not download image \(imagePath)")
            } else {
                
                completionHandler(data, nil)
            }
        }
        
        task.resume()
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let image = annotationCoreData.images?.allObjects[indexPath.row] as? Image
        delegate.stack.context.delete(image!)
        
        do {
            try delegate.stack.saveContext()
        }
        catch {
            fatalError()
        }
        
        collectionView.reloadData()
    }
    
    @IBAction func moreOptionBtnPressed(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        alertController.addAction(UIAlertAction(title: "Replace with new images", style: UIAlertActionStyle.default, handler: replaceWithNewImages))
        alertController.addAction(UIAlertAction(title: "Add new images", style: UIAlertActionStyle.default, handler: addNewImages))
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func addNewImages(action: UIAlertAction){
        CoreDataDownloadImage.downloadURLs(title: annotationCoreData.locationString!, latitude: annotationCoreData.latitude, longitude: annotationCoreData.longitude, page: Int(annotationCoreData.page!)!+1)
        AddImagesCollectionViewController.downloadingImageComplete = false
        
        fireTimerCheckingDownloadStatus()
    }
    
    func replaceWithNewImages(action: UIAlertAction){
        for image in (annotationCoreData.images?.allObjects)! {
            delegate.stack.context.delete((image as? Image)!)
        }
        do {
            try delegate.stack.saveContext()
        }
        catch {
            fatalError()
        }
        CoreDataDownloadImage.downloadURLs(title: annotationCoreData.locationString!, latitude: annotationCoreData.latitude, longitude: annotationCoreData.longitude, page: Int(annotationCoreData.page!)!+1)
        AddImagesCollectionViewController.downloadingImageComplete = false
        
        fireTimerCheckingDownloadStatus()
    }
}
