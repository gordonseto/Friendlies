
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
import SwiftOverlays

class feedVC: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, BroadcastCellDelegate, loginVCDelegate {

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
    
    var currentUser: User!
    var uid: String!
    
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
        tbc?.tabBar.barStyle = UIBarStyle.Black
        tbc?.tabBar.translucent = true
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
        noBroadcastsLabel.numberOfLines = 2
        
        firebase = FIRDatabase.database().reference()

        if let displayName = FIRAuth.auth()?.currentUser?.displayName {
            logUser((FIRAuth.auth()?.currentUser?.uid)!, username: displayName)
            beginFeedVC()
        } else {
            presentLoginVC()
        }
        
        broadcastContentView.hidden = true
        
        locationManager.delegate = self
        
    }
    
    func beginFeedVC(){
        uid = FIRAuth.auth()?.currentUser?.uid
        print(FIRAuth.auth()?.currentUser?.uid)
        let editor = BatchUser.editor()
        editor.setIdentifier(FIRAuth.auth()?.currentUser?.uid)
        editor.save()
        
        hexagonButton.userInteractionEnabled = false
        getCurrentUser(){
            self.hexagonButton.userInteractionEnabled = true
            self.locationAuthStatus()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        self.tabBarController?.tabBar.hidden = false
    }
    
    @IBAction func onHexagonTapped(sender: AnyObject) {
        if let _ = FIRAuth.auth()?.currentUser {
            if let firebase = firebase {
                if let uid = FIRAuth.auth()?.currentUser?.uid {
                    self.uid = uid
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
                                
                                firebase.child("broadcasts").child(self.currentUser.lastBroadcast).setValue(nil)
                                firebase.child("geolocations").child(self.currentUser.lastBroadcast).setValue(nil)
                                self.currentUser.lastBroadcast = key
                                CurrentUser.sharedInstance.user.lastBroadcast = key
                                firebase.child("users").child(uid).child("lastBroadcast").setValue(key)
                                
                                let delay = 0.5 * Double(NSEC_PER_SEC)
                                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                                dispatch_after(time, dispatch_get_main_queue()) {
                                    self.progressView.hidden = true
                                    self.progressView.progress = 0.5
                                    self.queryBroadcasts()
                                }
                                
                                self.notifyFollowers()
                            }
                            self.hexagonButton.userInteractionEnabled = true
                        })
                    }
                }
            }
        }
    }
    
    func notifyFollowers(){
        if currentUser == nil {
            CurrentUser.sharedInstance.getCurrentUser(){
                if let user = CurrentUser.sharedInstance.user {
                    self.currentUser = user
                    self.sendNotificationToFollowers()
                }
            }
        } else {
            sendNotificationToFollowers()
        }
    }
    
    func sendNotificationToFollowers(){
        self.currentUser.getFollowers(){
            if let followers = self.currentUser.followers {
                for (key, _) in followers {
                    NotificationsManager.sharedInstance.sendNotification(key, hasSound: false, groupId: "followNotifications", message: "\(self.currentUser.displayName) is available to play", deeplink: "friendlies://follows/\(self.currentUser.uid)")
                    NotificationsManager.sharedInstance.addToNotifications(key, notificationType: "follows", param1: self.currentUser.uid)
                }
            }
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
            circleQuery.observeEventType(.KeyEntered, withBlock: { (key: String!, location: CLLocation! ) in
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
        var receivedBroadcasts = 0
        for broadcastKey in broadcastKeys {
            if let key = broadcastKey["key"] as? String {
                if let location = broadcastKey["location"] as? CLLocation {
                    firebase.child("broadcasts").child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                        guard let authorUid = snapshot.value!["authorUid"] as? String else { return }
                        guard let broadcastDesc = snapshot.value!["broadcastDesc"] as? String else { return }
                        guard let hasSetup = snapshot.value!["hasSetup"] as? Bool else { return }
                        guard let time = snapshot.value!["time"] as? NSTimeInterval else { return }
                        let broadcast = Broadcast(key: key, authorUid: authorUid, broadcastDesc: broadcastDesc, hasSetup: hasSetup, geolocation: location, time: time)
                        
                        receivedBroadcasts += 1
                        
                        broadcast.getUser() {
                            self.currentUser.checkIfShouldBeAbleToSeeUserDetails(broadcast.user){ (should) in
                                if should {
                                    self.broadcasts.append(broadcast)
                                }
                                if receivedBroadcasts == self.broadcastKeys.count {
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
        print(broadcasts)
        filterBlockedBroadcasts(){
            self.broadcasts.sortInPlace {(broadcast1:Broadcast, broadcast2:Broadcast) -> Bool in
                broadcast1.time > broadcast2.time
            }
            self.finishedManipulatingBroadcasts()
        }
    }
    
    func finishedManipulatingBroadcasts(){
        self.refreshControl.endRefreshing()
        self.stopLoadingAnimation(self.activityIndicator, loadingLabel: self.loadingLabel)
        self.broadcastContentView.hidden = false
        self.tableView.reloadData()
        if self.broadcasts.count == 0 {
            self.displayBackgroundMessage("There are no broadcasts in your area. Be the first to post one!", label: self.noBroadcastsLabel, viewToAdd: self.tableView)
        } else {
            self.removeBackgroundMessage(self.noBroadcastsLabel)
        }
        if let tbc = self.tabBarController {
            NotificationsManager.sharedInstance.clearTabBarBadgeAtIndex(FEED_INDEX, tabBarController: tbc)
        }
        removeAllOverlays()
    }
    
    func filterBlockedBroadcasts(completion: ()->()){
        getCurrentUser(){
            self.currentUser.getBlockedInfo(){
                if let totalBlocked = self.currentUser.totalBlocked {
                    self.broadcasts = self.broadcasts.filter({totalBlocked[$0.authorUid] == nil})
                    completion()
                }
            }
        }
    }
    
    func getCurrentUser(completion: ()->()){
        if currentUser == nil {
            if CurrentUser.sharedInstance.user == nil {
                CurrentUser.sharedInstance.getCurrentUser(){
                    self.currentUser = CurrentUser.sharedInstance.user
                    completion()
                }
            } else {
                currentUser = CurrentUser.sharedInstance.user
                completion()
            }
        } else {
            completion()
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
                            if indexPath.row < self.tableView.numberOfRowsInSection(0) {
                                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                            }
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
        queryBroadcasts()
    }
    
    func presentLoginVC() {
        let delay = 0.01 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            let lvc: loginVC = self.generateLoginVC()
            lvc.delegate = self
            self.presentViewController(lvc, animated: true, completion: nil)
        }
    }
    
    func loginVCWillDismiss() {
        beginFeedVC()
    }
    
    func onTextViewEditing(textView: UITextView) {
        //tableView.setContentOffset(CGPointMake(0, textView.center.y-60), animated: true)
    }
    
    func deleteBroadcast(broadcast: Broadcast) {
//        self.startLoadingAnimation(self.activityIndicator, loadingLabel: self.loadingLabel, viewToAdd: self.tableView)
        firebase = FIRDatabase.database().reference()
        firebase.child("broadcasts").child(broadcast.key).setValue(nil)
        firebase.child("geolocations").child(broadcast.key).setValue(nil)
        firebase.child("users").child(broadcast.authorUid).child("lastAvailable").setValue(nil)
        firebase.child("users").child(broadcast.authorUid).child("lastBroadcast").setValue(nil)
        CurrentUser.sharedInstance.user.lastAvailable = nil
        showWaitOverlay()
        queryBroadcasts()
    }
    
    func onRemoveButtonPressed(broadcast: Broadcast, button: UIButton) {
        removeAlert(broadcast, button: button)
    }
    
    func removeAlert(broadcast: Broadcast, button: UIButton){
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let removeAction = UIAlertAction(title: "Delete", style: .Destructive) { action -> Void in
            button.userInteractionEnabled = false
            self.deleteBroadcast(broadcast)
        }
        alertController.addAction(removeAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
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
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
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
    
}
