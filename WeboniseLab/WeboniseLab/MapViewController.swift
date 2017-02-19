//
//  MapViewController.swift
//  WeboniseLab
//
//  Created by Netstratum on 2/18/17.
//  Copyright © 2017 irfan. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    var place : Place?
    fileprivate var photos = [[String:Any]]()
    fileprivate var resultPhotos = [Data]()
    @IBOutlet weak var collectionView : UICollectionView!
    
    fileprivate var pointAnnotation:CustomAnnotation!
    fileprivate var pinAnnotationView:MKPinAnnotationView!
    @IBOutlet weak var mapView : MKMapView!
    
    fileprivate func screenSize() -> CGSize {
        return UIScreen.main.bounds.size
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        guard let place = place else {
            return
        }
        
        let location = CLLocationCoordinate2D(latitude: place.pLocation.latitude, longitude: place.pLocation.longitude)
        let center = location
        let region = MKCoordinateRegionMake(center, MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025))
        mapView.setRegion(region, animated: true)
        
        pointAnnotation = CustomAnnotation()
        pointAnnotation.pinCustomImageData = place.iconData
        pointAnnotation.coordinate = location
        pointAnnotation.title = place.pName
        pointAnnotation.subtitle = place.pVicinity
        
        pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: "pin")
        mapView.addAnnotation(pointAnnotation)
        
        self.title = place.pName
        if let placePhotos = place.pPhotos {
            photos = placePhotos
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        let height = collectionView.bounds.size.height-5
        flowLayout.itemSize = CGSize(width: height, height: height)
        
        flowLayout.invalidateLayout()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
            return nil
        }
        
        let reuseIdentifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        let customAnnotation = annotation as! CustomAnnotation
        if let imageData = customAnnotation.pinCustomImageData {
            annotationView?.image = UIImage(data: imageData)
        }

        return annotationView
    }
}

extension MapViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    //
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GooglePhoto", for: indexPath) as! PhotoCell
        if resultPhotos.count <= indexPath.row {
            let photoDetail = photos[indexPath.row]
            let dimension = Int(collectionView.bounds.size.height)
            ServiceManager.sharedInstance.downloadImage(photoDetail["photo_reference"] as! String, dimension, dimension, completion: { [weak self](imageData, error) in
                if let strongSelf = self {
                    if error != nil {
                        strongSelf.resultPhotos.append(Data())
                    }
                
                    if let imageData = imageData {
                        cell.imgPhoto.image = UIImage(data: imageData)
                        strongSelf.resultPhotos.append(imageData)
                    }
                }
            })
        } else {
            cell.imgPhoto.image = UIImage(data: resultPhotos[indexPath.row])
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //
        guard let place = place else {
            return
        }
        
        let fileManager = FileManager.default
        let dirPaths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDir = dirPaths.first
        guard let fileURL = docsDir?.appendingPathComponent("\(place.pId)+\(indexPath.row).png") else {
            return
        }
        
        do {
            try resultPhotos[indexPath.row].write(to: fileURL)
            let alert = UIAlertController(title: "Webonise Lab",
                                          message: "Image saved",
                                          preferredStyle:.alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .cancel) { (alert: UIAlertAction) in
            }
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }catch let error as NSError {
            print(error)
            let alert = UIAlertController(title: "Webonise Lab",
                                          message: error.localizedDescription,
                                          preferredStyle:.alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .cancel) { (alert: UIAlertAction) in
            }
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.size.height-5
        return CGSize(width: height, height: height)
    }
}
