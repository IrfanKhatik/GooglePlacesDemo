//
//  ViewController.swift
//  WeboniseLab
//
//  Created by Netstratum on 2/18/17.
//  Copyright © 2017 irfan. All rights reserved.
//

import UIKit
import GooglePlaces

class ViewController: UIViewController {
    
    fileprivate var resultPlaces = [Place]()
    fileprivate var lastLocation: CLLocation?
    fileprivate var mapPlace : Place?
    
    @IBOutlet weak var tblPlaces: UITableView!
    
    // Computed property
    private var selected : GMSPlace!
    fileprivate var selectedPlace:GMSPlace {
        get {
            return selected
        }
        set(newPlace) {
            selected = newPlace
            getNearPlace(byName: selected.name)
        }
    }
    
    fileprivate var resultsViewController: GMSAutocompleteResultsViewController?
    fileprivate var searchController: UISearchController?
    fileprivate var resultView: UITextView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if lastLocation == nil {
            let locManager = LocationManager.sharedInstance
            locManager.delegate = self
            locManager.startUpdatingLocation()
        }
        
        tblPlaces.estimatedRowHeight = 70.0
        tblPlaces.rowHeight = UITableViewAutomaticDimension
        
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        // Put the search bar in the navigation bar.
        searchController?.searchBar.sizeToFit()
        searchController?.searchBar.barStyle = .blackOpaque
        navigationItem.titleView = searchController?.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching.
        searchController?.hidesNavigationBarDuringPresentation = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getNearPlace(byName name:String) -> Void {
        if lastLocation == nil {
            LocationManager.sharedInstance.startUpdatingLocation()
            return
        }
        
        ServiceManager.sharedInstance.getNearPlaces(name, lastLocation!) { [weak self] (places, error) in
            if let error = error {
                //error
                if let strongSelf = self {
                    let alert = UIAlertController(title: "Webonise Lab",
                                                  message: error.localizedDescription,
                                                  preferredStyle:.alert)
                
                    let okAction = UIAlertAction(title: "Ok", style: .cancel) { (alert: UIAlertAction) in
                    }
                    alert.addAction(okAction)
                    strongSelf.present(alert, animated: true, completion: nil)
                }
            }
            
            if let places = places {
                if let strongSelf = self {
                    strongSelf.resultPlaces = places
                    DispatchQueue.main.async {
                        strongSelf.tblPlaces.reloadData()
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let mapVC = segue.destination as! MapViewController
        mapVC.place = mapPlace!
    }
}

// Handle the user's selection.
extension ViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        searchController?.searchBar.text = place.name
        // Do something with the selected place.
        print("Place name: \(place.name)")
        selectedPlace = place
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1//resultPlaces.count > 0 ? 1 : 0
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell") as! PlaceCell
        let place = resultPlaces[indexPath.row]
        cell.lblName.text = place.pName
        cell.lblDetail.text = place.pVicinity
        if let imageData = place.iconData {
            cell.imgIcon.image = UIImage(data: imageData)
            return cell
        }
        guard let icon = place.pIcon else {
            return cell
        }
        
        let iconURL = URL(string: icon)
        ServiceManager.sharedInstance.downloadImageFromURL(iconURL!) { (iconData, error) in
            if let iconData = iconData {
                place.iconData = iconData
                DispatchQueue.main.async {
                    cell.imgIcon.image = UIImage(data: iconData)
                }
            }
            
            if let error = error {
                //place.iconData = temp
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
        mapPlace = resultPlaces[indexPath.row]
        performSegue(withIdentifier: "Show-Map", sender: self)
    }
}

extension ViewController: LocationManagerDelegate {
    func tracingLocation(_ currentLocation: CLLocation) {
        lastLocation = currentLocation
    }
    func tracingLocationDidFailWithError(_ error: NSError) {
        let alert = UIAlertController(title: "Webonise Lab",
                                      message: error.localizedDescription,
                                      preferredStyle:.alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .cancel) { (alert: UIAlertAction) in
        }
        alert.addAction(okAction)
    }
}

