//
//  LocationViewController.swift
//  CheckIn
//
//  Created by Deniz Adil on 15.1.21.
//

import UIKit
import MapKit
import CoreLocation
import SVProgressHUD

protocol CreateMomentDelegate: class {
    func didPostItem(item: Feed)
}
class LocationViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    let manager = CLLocationManager()
    
    weak var delegate: CreateMomentDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTitle()
        setBackButton()
        setAddLocation()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        manager.requestWhenInUseAuthorization()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
    }
    
    func setTitle() {
        title = "Your Location"
        let titleAttributes = [NSAttributedString.Key.foregroundColor:UIColor.darkGray, NSAttributedString.Key.font:UIFont.systemFont(ofSize: 13, weight: .medium)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes as [NSAttributedString.Key : Any]
    }
    
    func setBackButton() {
        let back = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        back.setImage(UIImage(named: "BackButton"), for: .normal)
        back.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: back)
    }
    
    @objc func onBack() {
        navigationController?.popViewController(animated: true)
    }
    
    func setAddLocation() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 36, height: 14))
        button.setTitle("Add Location", for: .normal)
        let titleColor = UIColor.systemBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .light)
        button.setTitleColor(titleColor, for: .normal)
        button.addTarget(self, action: #selector(onAddLocation), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        }
    
    @objc func onAddLocation() {
//        guard let localUser = DataStore.shared.localUser else { return }
//        var moment = Feed()
//        moment.creatorId = localUser.id
//        moment.createdAt = Date().toMiliseconds()
//        DataStore.shared.uploadImage(image: <#T##UIImage#>, itemId: <#T##String#>, completion: <#T##(URL?, Error?) -> Void#>)
        performSegue(withIdentifier: "Home", sender: nil)
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            manager.stopUpdatingLocation()
            render(location)
        }
    }
    func render(_ location: CLLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        mapView.addAnnotation(pin)
    }
}
