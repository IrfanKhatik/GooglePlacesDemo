//
//  ServiceManager.swift
//  WeboniseLab
//
//  Created by Netstratum on 2/18/17.
//  Copyright © 2017 irfan. All rights reserved.
//

import UIKit
import CoreLocation

public class ServiceManager: NSObject {
    
    static let sharedInstance = ServiceManager()
    private var session: URLSession!
    private override init(){
        // initializer code here
        session = URLSession.shared
    }
    
    private func nearBySearchURL() -> String {
        return "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
    }
    
    private func photoURL() -> String {
        return "https://maps.googleapis.com/maps/api/place/photo?"
    }
    
    enum ParseError: Error {
        case Empty
        case Short
        case Dirty
    }
    
    //https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670,151.1957&radius=500&types=food&name=cruise&key=YOUR_API_KEY
    
    func getNearPlaces(_ searchKey: String,_ loc: CLLocation, completion:@escaping(_ places: Array<Place>?, _ error: Error?)-> Void) -> Void {
        let query = "key"+"="+kPlacesAPIKey+"&"+"name"+"="+searchKey+"&"+"location"+"="+"\(loc.coordinate.latitude)"+","+"\(loc.coordinate.longitude)"+"&"+"rankby"+"="+"distance"
        
        let urlstr = "\(nearBySearchURL())"+query
        let serviceURL = URL(string: urlstr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        let request : URLRequest = URLRequest(url: serviceURL!)
        
        session.dataTask(with: request) { (data, response, error) in
            guard
                let responseData:Data = data,
                let _:URLResponse = response else
            {
                print("error : \(error?.localizedDescription)")
                completion(nil,error)
                return
            }
            do {
                let parsedData = try JSONSerialization.jsonObject(with: responseData, options: []) as! [String:Any]
                guard let results = parsedData["results"] as? [[String:Any]] else {
                    completion(nil,error)
                    return
                }
                
                var places = [Place]()
                
                for placeDetail in results {
                    let place : Place = Place()
                    
                    if let pId = placeDetail["place_id"] as? String {
                        place.pId = pId
                    } else {
                        place.pId = ""
                        continue
                    }
                    
                    if let name = placeDetail["name"] as? String {
                        place.pName = name
                    } else {
                        place.pName = ""
                        continue
                    }
                    
                    if let vicinity = placeDetail["vicinity"] as? String {
                        place.pVicinity = vicinity
                    } else {
                        place.pVicinity = ""
                    }
                    
                    if let icon = placeDetail["icon"] as? String {
                        place.pIcon = icon
                    } else {
                        place.pIcon = ""
                    }
                    
                    if let loc = (placeDetail["geometry"] as? [String:Any])?["location"] as? [String:Double] {
                        place.pLocation = location(latitude: Double(loc["lat"]!) , longitude: Double(loc["lng"]!))
                    } else {
                        place.pLocation = location(latitude: 0.0, longitude: 0.0)
                    }
                    
                    if let photos = placeDetail["photos"] as? [[String:Any]] {
                        place.pPhotos = photos
                    } else {
                        place.pPhotos = nil
                    }
                    places.append(place)
                }
                
                completion(places, nil)
                
            }catch let error as NSError {
                print(error)
                completion(nil, error)
            }
        }.resume()
    }
    
    //https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=CnRtAAAATLZNl354RwP_9UKbQ_5Psy40texXePv4oAlgP4qNEkdIrkyse7rPXYGd9D_Uj1rVsQdWT4oRz4QrYAJNpFX7rzqqMlZw2h2E2y5IKMUZ7ouD_SlcHxYq1yL4KbKUv3qtWgTK0A6QbGh87GB3sscrHRIQiG2RrmU_jF4tENr9wGS_YxoUSSDrYjWmrNfeEHSGSc3FyhNLlBU&key=YOUR_API_KEY
    
    func downloadImage(_ reference: String,_ height: Int,_ width: Int, completion:@escaping(_ imageData: Data?, _ error: Error?)-> Void){
        let query = "key"+"="+kPlacesAPIKey+"&"+"photoreference"+"="+reference+"&"+"maxheight"+"="+"\(height)"+"&"+"maxwidth"+"="+"\(width)"
        let urlstr = "\(photoURL())"+query
        let downloadURL = URL(string: urlstr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        downloadImageFromURL(downloadURL!, completion: completion)
    }
    
    func downloadImageFromURL(_ imageURL: URL, completion:@escaping(_ imageData: Data?, _ error: Error?)-> Void){
        session.dataTask(with: imageURL, completionHandler: { (data, response, error) -> Void in
            guard
                let responseData:Data = data,
                let _:URLResponse = response
                else {
                    completion(nil, error)
                    return
            }
            completion(responseData, nil)
        }).resume()
    }
}
