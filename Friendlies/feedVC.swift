
//
//  feedVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import GeoFire

class feedVC: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var hexagonButton: UIButton!
    
    @IBOutlet weak var broadcastContentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    
    let locationManager = CLLocationManager()
    
    var currentLocation: CLLocation!
    
    var firebase: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let tbc = self.tabBarController
        tbc?.tabBar.barStyle = UIBarStyle.BlackOpaque
        tbc?.tabBar.selectedImageTintColor = UIColor.whiteColor()
        
        self.hideKeyboardWhenTappedAround()
        
        self.scrollView.scrollEnabled = true
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.delaysContentTouches = false
        
        firebase = FIRDatabase.database().reference()
        
        if let user = FIRAuth.auth()?.currentUser {
            print(user.displayName)
            print(user.photoURL)
            print(user.uid)
        } else {
            presentLoginVC()
        }
        
        locationManager.delegate = self
        
        locationAuthStatus()
    }
    
    @IBAction func onHexagonTapped(sender: AnyObject) {
        if let user = FIRAuth.auth()?.currentUser {
            if let firebase = firebase {
                if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
                    if let currentLocation = currentLocation {
                        hexagonButton.userInteractionEnabled = false
                        let key = firebase.child("broadcasts").childByAutoId().key
                        let broadcastDesc = "Available to play"
                        var hasSetup: Bool
                        if let hs = NSUserDefaults.standardUserDefaults().objectForKey("HAS_SETUP") as? Bool{
                            hasSetup = hs
                        } else {
                            hasSetup = false
                        }
                        let geolocation = currentLocation
                        let time = NSDate().timeIntervalSince1970
                        let broadcast: [String: AnyObject] = ["authorUid": uid, "broadcastDesc": broadcastDesc, "hasSetup": hasSetup, "time": time]
                        firebase.child("broadcasts").child(key).setValue(broadcast)
                        firebase.child("users").child(uid).child("lastAvailable").setValue(time)
                    
                        let geoFire = GeoFire(firebaseRef: firebase.child("geolocations"))
                        geoFire.setLocation(currentLocation, forKey: key, withCompletionBlock: { (error) in
                            if error != nil {
                                print(error.localizedDescription)
                            } else {
                                self.hexagonButton.userInteractionEnabled = true
                            }
                        })
                    }
                }
            }
        } else {
            presentLoginVC()
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print(location)
            self.currentLocation = location
        }
    }

    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("yo")
    }
    
    
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func generateLoginVC() -> loginVC {
        let lvc = self.storyboard?.instantiateViewControllerWithIdentifier("loginVC") as! loginVC
        return lvc
    }
    
    func presentLoginVC() {
        let delay = 0.01 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            let lvc: loginVC = self.generateLoginVC()
            self.presentViewController(lvc, animated: true, completion: nil)
        }
    }
}