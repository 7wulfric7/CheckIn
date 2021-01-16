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

protocol LocationDelegate: class {
    func didPostItem(item: Feed)
}
class LocationViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapImage: UIImageView!
    @IBOutlet weak var location: UILabel!
    
    let manager = CLLocationManager()
    var pickedImage: UIImage?
    weak var delegate: LocationDelegate?
    var feedItems = [Feed]()
    var moment = Feed()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTitle()
        setBackButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
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
    
    @IBAction func onAddLocation(_ sender: UIButton) {
        manager.requestWhenInUseAuthorization()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        mapView.showsUserLocation = true
        mapImage.image = pickedImage
        guard let localUser = DataStore.shared.localUser else {
            return
        }
        guard let pickedImage = pickedImage else {
//            showErrorWith(title: "Error", msg: "Image not found")
            return
        }
//        guard let location = location.text else {
//            showErrorWith(title: "Error", msg: "No location description")
//            return
//        }
        
//        moment.location = location
//        moment.creatorId = localUser.id
//        moment.createdAt = Date().toMiliseconds()
        SVProgressHUD.show()
        let uuid = UUID().uuidString
//        guard let feedId = moment.id else { return }
        DataStore.shared.uploadImage(image: pickedImage, itemId: uuid, isUserImage: false) { (url, error) in
            if let error = error {
                SVProgressHUD.dismiss()
                print(error.localizedDescription)
                self.showErrorWith(title: "Error", msg: error.localizedDescription)
                return
            }
            if let url = url {
                self.moment.imageUrl = url.absoluteString
                DataStore.shared.createFeedItem(item: self.moment) { (feed, error) in
                    if let error = error {
                        self.showErrorWith(title: "Error", msg: error.localizedDescription)
                        return
                    }
                }
                return
            }
            SVProgressHUD.dismiss()
        }
        self.feedItems.append(moment)
        self.continueToHome()
//        performSegue(withIdentifier: "Home", sender: nil)
    }
    
    func continueToHome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Home")
        present(controller, animated: true, completion: nil)
        navigationController?.popToRootViewController(animated: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location:CLLocation = locations[0] as CLLocation
            manager.stopUpdatingLocation()
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: false)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if (error != nil){
                print("error in reverseGeocode")
            }
            let placemark = placemarks! as [CLPlacemark]
            if placemark.count > 0 {
                let placemark = placemarks![0]
                self.location.text = "\(placemark.name!), \(placemark.administrativeArea!), \(placemark.country!)"
            }
        }
//        let pin = MKPointAnnotation()
//        pin.coordinate = coordinate
//        mapView.addAnnotation(pin)
        
        
        let options = MKMapSnapshotter.Options()
        options.region = mapView.region
        options.size = mapView.frame.size
        options.scale = UIScreen.main.scale
        let rect = mapImage.bounds
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot else {
                print("Snapshot error: \(error!.localizedDescription)")
                return
            }
            let image = UIGraphicsImageRenderer(size: options.size).image { _ in
                snapshot.image.draw(at: .zero)
                let pinView = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
                let pinImage = pinView.image
                var point = snapshot.point(for: location.coordinate)
                if rect.contains(point) {
                    point.x -= pinView.bounds.width / 2
                    point.y -= pinView.bounds.height / 2
                    point.x += pinView.centerOffset.x
                    point.y += pinView.centerOffset.y
                    pinImage?.draw(at: point)
                }
            }
            self.pickedImage = image
        }
    }
}
