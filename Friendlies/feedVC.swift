
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
import Batch
import SloppySwiper

class feedVC: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, BroadcastCellDelegate {

    @IBOutlet weak var hexagonButton: UIButton!
    
    @IBOutlet weak var broadcastContentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressView: UIProgressView!
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation!
    
    var firebase: FIRDatabaseReference!
    var geofire: GeoFire!
    
    var refreshControl: UIRefreshControl!
    
    var hasLoadedBroadcasts = false
    
    var broadcasts = [Broadcast]()
    var broadcastKeys = [[String:AnyObject]]()
    
    var activityIndicator: UIActivityIndicatorView!
    var loadingLabel: UILabel!
    var noLocationLabel: UILabel!
    
    var downloadedImages = [String: UIImage]()
    var pendingDownloads = [Int: String]()
    var uidsBeingDownloaded = [String]()
    
    var noBroadcastsLabel: UILabel!
    
    var swiper: SloppySwiper!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = true
        //self.navigationController?.interactivePopGestureRecognizer!.delegate = nil;
        if let navigationcontroller = self.navigationController {
            swiper = SloppySwiper(navigationController: navigationcontroller)
            navigationcontroller.delegate = swiper
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true
        
        let tbc = self.tabBarController
        tbc?.tabBar.barStyle = UIBarStyle.BlackOpaque
        tbc?.tabBar.selectedImageTintColor = UIColor.whiteColor()
        
        self.hideKeyboardWhenTappedAround()
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingLabel = UILabel(frame: CGRectMake(0, 0, 100, 30))
        noLocationLabel = UILabel(frame: CGRectMake(0, 0, 100, 30))
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refreshView:"), forControlEvents: UIControlEvents.ValueChanged)
        refreshControl.tintColor = UIColor.lightGrayColor()
        self.tableView.addSubview(refreshControl)
        self.tableView.scrollEnabled = true
        self.tableView.alwaysBounceVertical = true
        self.tableView.delaysContentTouches = false
        
        noBroadcastsLabel = UILabel(frame: CGRectMake(0, 0, 220, 120))
        
        firebase = FIRDatabase.database().reference()

        if let displayName = FIRAuth.auth()?.currentUser?.displayName {
            print(displayName)
            print(FIRAuth.auth()?.currentUser?.uid)
            let editor = BatchUser.editor()
            editor.setIdentifier(FIRAuth.auth()?.currentUser?.uid)
            editor.save()
            
            updateTabBarBadge("messages")
            updateTabBarBadge("friends")
            
            updateIconBadge()
        } else {
            presentLoginVC()
        }
        
        broadcastContentView.hidden = true
        
        locationManager.delegate = self
        
        locationAuthStatus()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        self.tabBarController?.tabBar.hidden = false
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
                                self.progressView.hidden = false
                                self.progressView.progress = 0.75
                                self.progressView.setProgress(1, animated: true)
                                let delay = 0.5 * Double(NSEC_PER_SEC)
                                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                                dispatch_after(time, dispatch_get_main_queue()) {
                                    self.progressView.hidden = true
                                    self.progressView.progress = 0.5
                                    self.queryBroadcasts()
                                }
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
            if broadcasts.count == 0 {
                self.startLoadingAnimation(self.activityIndicator, loadingLabel: self.loadingLabel, viewToAdd: self.tableView)
                removeBackgroundMessage(noBroadcastsLabel)
            }
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
                        broadcast.getUser() {
                            self.broadcasts.append(broadcast)
                            if let author = broadcast.user {
                                if self.broadcasts.count == self.broadcastKeys.count {
                                    self.sortBroadcasts()
                                }
                            }
                        }
                    })
                }
            }
        }
        if broadcastKeys.count == 0 {
            sortBroadcasts()
        }
    }
    
    func sortBroadcasts(){
        broadcasts.sortInPlace {(broadcast1:Broadcast, broadcast2:Broadcast) -> Bool in
            broadcast1.time > broadcast2.time
        }
        print(broadcasts)
        self.refreshControl.endRefreshing()
        stopLoadingAnimation(activityIndicator, loadingLabel: loadingLabel)
        broadcastContentView.hidden = false
        tableView.reloadData()
        if broadcasts.count == 0 {
            displayBackgroundMessage("There are no broadcasts near this area!", label: noBroadcastsLabel, viewToAdd: tableView)
        } else {
            removeBackgroundMessage(noBroadcastsLabel)
        }
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
        getProfilePhoto(broadcast.user, indexPath: indexPath)
        cell.delegate = self
        cell.configureCell(broadcast)
        if let currentloc = currentLocation {
            cell.findDistanceFrom(currentloc)
        }
        return cell
    }
    
    func getProfilePhoto(user: User, indexPath: NSIndexPath){
        if downloadedImages[user.uid] == nil {
            if uidsBeingDownloaded.contains(user.uid) {
                print("pending download for \(user.displayName)")
                pendingDownloads[indexPath.row] = user.uid
            } else {
                print("downloading \(user.displayName)")
                uidsBeingDownloaded.append(user.uid)
                pendingDownloads[indexPath.row] = user.uid
                user.getUserProfilePhoto() {
                    self.downloadedImages[user.uid] = user.profilePhoto
                    for (index, uid) in self.pendingDownloads {
                        if uid == user.uid {
                            let indexPath = NSIndexPath(forRow: index, inSection: 0)
                            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                        }
                    }
                    if let index = self.uidsBeingDownloaded.indexOf(user.uid) {
                        self.uidsBeingDownloaded.removeAtIndex(index)
                    }
                }
            }
        } else {
            user.profilePhoto = downloadedImages[user.uid]
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return broadcasts.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let user = broadcasts[indexPath.row].user {
            performSegueWithIdentifier("profileVCFromFeed", sender: user)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func refreshView(sender: AnyObject){
        hasLoadedBroadcasts = false
    }
    
    func onTextViewEditing(textView: UITextView) {
        //tableView.setContentOffset(CGPointMake(0, textView.center.y-60), animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "profileVCFromFeed" {
            if let pvc = segue.destinationViewController as? profileVC {
                pvc.user = sender as! User
                pvc.notFromTabBar = true
            }
        }
    }
}

extension UIViewController {
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tap.cancelsTouchesInView = false
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
    
    
    func startLoadingAnimation(activityIndicator: UIActivityIndicatorView, loadingLabel: UILabel, viewToAdd: UIView){
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityIndicator.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2 - 32, UIScreen.mainScreen().bounds.size.height/2 - 90)
        activityIndicator.startAnimating()
        viewToAdd.addSubview(activityIndicator)
        
        loadingLabel.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2 + 32, UIScreen.mainScreen().bounds.size.height/2 - 90)
        loadingLabel.text = "Loading..."
        loadingLabel.textColor = UIColor.whiteColor()
        viewToAdd.addSubview(loadingLabel)
    }
    
    func stopLoadingAnimation(activityIndicator: UIActivityIndicatorView, loadingLabel: UILabel){
        activityIndicator.removeFromSuperview()
        loadingLabel.removeFromSuperview()
    }
    
    func displayBackgroundMessage(message: String, label: UILabel, viewToAdd: UIView) {
        label.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2, UIScreen.mainScreen().bounds.size.height/2 - 90)
        label.text = message
        label.textAlignment = .Center
        label.font = UIFont(name: "HelveticaNeue", size: 15)
        label.textColor = UIColor.darkGrayColor()
        viewToAdd.addSubview(label)
    }
    
    func removeBackgroundMessage(label: UILabel!){
        if let label = label {
            label.removeFromSuperview()
        }
    }
    
    
    func updateTabBarBadge(queryType: String){
        if let user = FIRAuth.auth()?.currentUser {
            let firebase = FIRDatabase.database().reference()
            firebase.child("notifications").child(user.uid).child(queryType).observeSingleEventOfType(.Value, withBlock: {(snapshot) in
                print(snapshot.childrenCount)
                
                var index: Int!
                if queryType == "messages" {
                    index = MESSAGES_INDEX
                } else if queryType == "friends" {
                    index = FRIENDS_INDEX
                }
                
                if snapshot.childrenCount == 0 {
                    self.tabBarController?.tabBar.items?[index].badgeValue = nil
                } else {
                    self.tabBarController?.tabBar.items?[index].badgeValue = "\(snapshot.childrenCount)"
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func dismissNotifications(){
        //let firebase = FIRDatabase.database().reference()
        //if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String  {
            //firebase.child("users").child(uid).child("notifications").setValue(0)
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        BatchPush.dismissNotifications()
            //BatchPush.dismissNotifications()
            //NSUserDefaults.standardUserDefaults().setObject(0, forKey: "NOTIFICATIONS")
        //}
    }
}

func updateIconBadge(){
    if let user = FIRAuth.auth()?.currentUser {
        getNumberOfNotifications(user.uid){(sum) in
            UIApplication.sharedApplication().applicationIconBadgeNumber = sum
        }
    }
}

func getNumberOfNotifications(uid: String, completion: (Int)->()) {
    let firebase = FIRDatabase.database().reference()
    firebase.child("notifications").child(uid).observeSingleEventOfType(.Value, withBlock: {(snapshot) in
        var sum: Int = 0
        
        for child in snapshot.children {
            sum += Int(child.childrenCount!)
        }
        
        completion(sum)
        
    }) { (error) in
        print(error.localizedDescription)
    }
}