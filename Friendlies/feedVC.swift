
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
    var geofire: GeoFire!
    
    var refreshControl: UIRefreshControl!
    
    var hasLoadedBroadcasts = false
    
    var broadcasts = [Broadcast]()
    var broadcastKeys = [[String:AnyObject]]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let tbc = self.tabBarController
        tbc?.tabBar.barStyle = UIBarStyle.BlackOpaque
        tbc?.tabBar.selectedImageTintColor = UIColor.whiteColor()
        
        self.hideKeyboardWhenTappedAround()
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refreshView:"), forControlEvents: UIControlEvents.ValueChanged)
        refreshControl.tintColor = UIColor.lightGrayColor()
        self.tableView.addSubview(refreshControl)
        self.tableView.scrollEnabled = true
        self.tableView.alwaysBounceVertical = true
        self.tableView.delaysContentTouches = false
        
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
                                print("broadcast sent")
                            }
                            self.hexagonButton.userInteractionEnabled = true
                        })
                    }
                }
            }
        } else {
            presentLoginVC()
        }
    }
    
    func queryBroadcasts() {
        if let currentloc = currentLocation {
            hasLoadedBroadcasts = true
        
            let geofireRef = firebase.child("geolocations")
            geofire = GeoFire(firebaseRef: geofireRef)
        
            var radius: Double
            if let rad = NSUserDefaults.standardUserDefaults().objectForKey("SEARCH_RADIUS") as? Double {
                radius = rad
            } else {
                radius = 30 //km
                NSUserDefaults.standardUserDefaults().setObject(radius, forKey: "SEARCH_RADIUS")
            }
            
            broadcastKeys = []
            broadcasts = []
            
            let circleQuery = geofire.queryAtLocation(currentloc, withRadius: radius)
            let queryHandle = circleQuery.observeEventType(.KeyEntered, withBlock: { (key: String!, location: CLLocation! ) in
                let broadcastKey = ["key": key, "location": location]
                self.broadcastKeys.append(broadcastKey)
            })
            
            circleQuery.observeReadyWithBlock({
                circleQuery.removeAllObservers()
                self.getBroadcastsFromKeys()
            })
        }
    }
    
    func getBroadcastsFromKeys(){
        var broadcastsRetrieved = 0
        for broadcastKey in broadcastKeys {
            if let key = broadcastKey["key"] as? String {
                if let location = broadcastKey["location"] as? CLLocation {
                    firebase.child("broadcasts").child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                        guard let authorUid = snapshot.value!["authorUid"] as? String else { return }
                        guard let broadcastDesc = snapshot.value!["broadcastDesc"] as? String else { return }
                        guard let hasSetup = snapshot.value!["hasSetup"] as? Bool else { return }
                        guard let time = snapshot.value!["time"] as? NSTimeInterval else { return }
                        let broadcast = Broadcast(key: key, authorUid: authorUid, broadcastDesc: broadcastDesc, hasSetup: hasSetup, geolocation: location, time: time)
                        self.broadcasts.append(broadcast)
                        
                        if self.broadcasts.count == self.broadcastKeys.count {
                            self.sortBroadcasts()
                        }
                    })
                }
            }
        }
        if broadcastKeys.count == 0 {
            self.refreshControl.endRefreshing()
            tableView.reloadData()
        }
    }
    
    func sortBroadcasts(){
        broadcasts.sort({$0.time > $1.time})
        print(broadcasts)
        self.refreshControl.endRefreshing()
        tableView.reloadData()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            //print(location)
            self.currentLocation = location
            if !hasLoadedBroadcasts {
                queryBroadcasts()
            }
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
        let cell = tableView.dequeueReusableCellWithIdentifier("BroadcastCell", forIndexPath: indexPath) as! BroadcastCell
        let broadcast = broadcasts[indexPath.row]
        cell.configureCell(broadcast)
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return broadcasts.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("yo")
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func refreshView(sender: AnyObject){
        hasLoadedBroadcasts = false
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