//
//  TableViewController.swift
//  FeedTester
//
//  Created by Francesco Prospato on 9/12/17.
//  Copyright © 2017 Francesco Prospato. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    
    //activity indicator
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makenewsIndicator()
        loadNews()
    }

    func loadNews() {
        //allocate var inside ViewController
        var tableObjects: [QueryObject] = []
        var newsLeftNumber = Int()
        func loadnews() {
            newsIndicator.startAnimating()
            //start finding humaners
            let humanQuery = PFQuery(className: "human")
            humanQuery.whereKey("follower", equalTo: PFUser.current()?.objectId! ?? String())
            humanQuery.findObjectsInBackground { (objects, error) in
                if error == nil {
                    //clean humanArray
                    self.tableObjects.removeAll(keepingCapacity: false)
                    self.humanArray.removeAll(keepingCapacity: false)
                    
                    //find users we are humaning
                    for object in objects!{
                        self.humanArray.append(object.object(forKey: "following") as! String)
                    }
                    let countQuery = PFQuery(className: "News")
                    countQuery.whereKey("user", containedIn: self.humanArray)
                    countQuery.countObjectsInBackground(block: { (count, error) in
                        if error == nil {
                            if count > 0 {
                                self.newsLeftNumber = Int(count)
                                
                                //getting related news animal
                                let newsQuery = PFQuery(className: "News")
                                newsQuery.whereKey("user", containedIn: self.humanArray) //find this info from who we're humaning
                                newsQuery.limit = self.page
                                newsQuery.addDescendingOrder("createdAt") //get most recent
                                newsQuery.findObjectsInBackground(block: { (objects, error) in
                                    if error == nil {
                                        let dispathGroup = DispatchGroup()
                                        for object in objects! {
                                            //detecting the type of the object
                                            self.newsTypeArray.append(object.object(forKey: "type") as! String)
                                            let type = object.object(forKey: "type") as! String
                                            let owner = object.object(forKey: "user") as! String
                                            let id = object.object(forKey: "id") as! String
                                            let date = object.createdAt
                                            
                                            print(self.tableObjects.count)
                                            if self.tableObjects.count == self.page || self.tableObjects.count == self.newsLeftNumber {
                                                self.newsIndicator.stopAnimating()
                                                self.tableView.reloadData()
                                            }
                                            
                                            dispathGroup.enter()
                                            
                                            if type == "element" {
                                                let query = PFQuery(className: "Elements")
                                                query.whereKey("objectId", equalTo: id)
                                                query.findObjectsInBackground { (elementObjects, error) in
                                                    if error == nil {
                                                        for elementObject in elementObjects! {
                                                            //add to variables
                                                            let objectID = elementObject.objectId
                                                            let userID = elementObject.object(forKey: "userID") as! String
                                                            let elementType = elementObject.object(forKey: "elementType") as! String
                                                            var fullname = String()
                                                            var userProfilePic = UIImage()
                                                            
                                                            //get user info
                                                            let userQuery = PFUser.query()
                                                            userQuery?.whereKey("objectId", equalTo: owner)
                                                            userQuery?.findObjectsInBackground(block: { (userObjects, error) in
                                                                if error == nil {
                                                                    for userObject in userObjects! {
                                                                        fullname = userObject.object(forKey: "fullname") as! String
                                                                        let pic = userObject.value(forKey: "profilePhoto") as! PFFile
                                                                        pic.getDataInBackground(block: { (data, error) in
                                                                            if error == nil {
                                                                                userProfilePic = UIImage(data: data!)!
                                                                                
                                                                                //add to queryObject
                                                                                let newelement = Element()
                                                                                newelement.owner = owner
                                                                                newelement.id = id
                                                                                newelement.date = date
                                                                                
                                                                                newelement.ownerFullname = fullname
                                                                                newelement.ownerProfilePic = userProfilePic
                                                                                
                                                                                newelement.objectID = objectID
                                                                                newelement.userID = userID
                                                                                newelement.elementType = elementType
                                                                                self.tableObjects.append(newelement)
                                                                                dispathGroup.leave()
                                                                            } else {
                                                                                print(error?.localizedDescription ?? String())
                                                                            }
                                                                        })
                                                                    }
                                                                } else {
                                                                    self.newsIndicator.stopAnimating()
                                                                     print(error?.localizedDescription ?? String() 
                                                                }
                                                            })
                                                            
                                                        }
                                                    } else {
                                                        self.newsIndicator.stopAnimating()
                                                        print(error.localizedDescription ?? String()) 
                                                        
                                                    }
                                                }
                                            } else if type == "human" {
                                                let humanQuery = PFQuery(className: "Human")
                                                humanQuery.whereKey("objectId", equalTo: id)
                                                humanQuery.limit = 1
                                                humanQuery.findObjectsInBackground(block: { (humanObjects, error) in
                                                    if error == nil {
                                                        for humanObject in humanObjects! {
                                                            let otherObjectID = humanObject.object(forKey: "following") as! String
                                                            
                                                            var fullname = String()
                                                            var userProfilePic = UIImage()
                                                            
                                                            //get info of user
                                                            let userQuery = PFUser.query()
                                                            userQuery?.whereKey("objectId", equalTo: owner)
                                                            userQuery?.findObjectsInBackground(block: { (userObjects, error) in
                                                                if error == nil {
                                                                    print(userObjects)
                                                                    for userObject in userObjects! {
                                                                        fullname = userObject.object(forKey: "fullname") as! String
                                                                        let pic = userObject.value(forKey: "profilePhoto") as! PFFile
                                                                        pic.getDataInBackground(block: { (data, error) in
                                                                            if error == nil {
                                                                                userProfilePic = UIImage(data: data!)!
                                                                                
                                                                                //from begining query
                                                                                let newhuman = Human()
                                                                                newhuman.owner = owner
                                                                                newhuman.id = id
                                                                                newhuman.date = date
                                                                                
                                                                                //info of user humaning
                                                                                newhuman.ownerFullname = fullname
                                                                                newhuman.ownerProfilePic = userProfilePic
                                                                                
                                                                                //info for cell
                                                                                newhuman.humaning = otherObjectID
                                                                                self.tableObjects.append(newhuman)
                                                                                dispathGroup.leave()
                                                                            } else {
                                                                                print(error?.localizedDescription ?? String())
                                                                            }
                                                                        })
                                                                    }
                                                                } else {
                                                                    self.newsIndicator.stopAnimating()
                                                                     print(error?.localizedDescription ?? String() 
                                                                }
                                                            })
                                                        }
                                                    } else {
                                                        self.newsIndicator.stopAnimating()
                                                         print(error?.localizedDescription ?? String() 
                                                    }
                                                })
                                                
                                            } else if type == "animal"{
                                                let animalQuery = PFQuery(className: "Animals")
                                                animalQuery.whereKey("objectId", equalTo: id)
                                                animalQuery.limit = 1
                                                animalQuery.findObjectsInBackground(block: { (animalObjects, error) in
                                                    if error == nil {
                                                        for animalObject in animalObjects! {
                                                            let objectID = animalObject.objectId
                                                            let animalType = animalObject.object(forKey: "animalType") as! String
                                                            
                                                            var fullname = String()
                                                            var userProfilePic = UIImage()
                                                            
                                                            //get user info
                                                            let userQuery = PFUser.query()
                                                            userQuery?.whereKey("objectId", equalTo: owner)
                                                            userQuery?.findObjectsInBackground(block: { (userObjects, error) in
                                                                if error == nil {
                                                                    for userObject in userObjects! {
                                                                        fullname = userObject.object(forKey: "fullname") as! String
                                                                        let pic = userObject.value(forKey: "profilePhoto") as! PFFile
                                                                        pic.getDataInBackground(block: { (data, error) in
                                                                            if error == nil {
                                                                                userProfilePic = UIImage(data: data!)!
                                                                                
                                                                                let newanimal = Animal()
                                                                                newanimal.owner = owner
                                                                                newanimal.id = id
                                                                                newanimal.date = date
                                                                                
                                                                                newanimal.ownerFullname = fullname
                                                                                newanimal.ownerProfilePic = userProfilePic
                                                                                
                                                                                newanimal.objectID = objectID
                                                                                newanimal.animalType = animalType
                                                                                self.tableObjects.append(newanimal)
                                                                                dispathGroup.leave()
                                                                            } else {
                                                                                self.newsIndicator.stopAnimating()
                                                                                 print(error?.localizedDescription ?? String() 
                                                                            }
                                                                        })
                                                                    }
                                                                } else {
                                                                    self.newsIndicator.stopAnimating()
                                                                     print(error?.localizedDescription ?? String() 
                                                                }
                                                            })
                                                        }
                                                    } else {
                                                        self.newsIndicator.stopAnimating()
                                                         print(error?.localizedDescription ?? String() 
                                                    }
                                                })
                                            }
                                            
                                            
                                        }
                                        
                                    } else {
                                        self.newsIndicator.stopAnimating()
                                         print(error?.localizedDescription ?? String() 
                                    }
                                })
                            }
                        } else {
                            self.newsIndicator.stopAnimating()
                             print(error?.localizedDescription ?? String() 
                        }
                    })
                    
                } else {
                    self.newsIndicator.stopAnimating()
                     print(error?.localizedDescription ?? String() 
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tableObjects.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //now we can detect what object we have and show correct cell depending on object's type
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            print(tableObjects)
            let object = tableObjects[indexPath.row]
            let type = newsTypeArray[indexPath.row]
            
            
            //making downcast or if you won't use subclasses, then check type variable using switch case as I made in loadNews()
            if type == "element" {
                if let element = object as? Element,
                    let cell = tableView.dequeueReusableCell(withIdentifier: "elementCell") as? NewElementCell {
                    
                    //owner function
                    cell.userProfilePhoto.image = element.ownerProfilePic
                    
                    //Will add human stuff later
                    
                    //return cell
                    return cell
                }
            } else if type == "human" {
                
                if let human = object as? Human,
                    let cell = tableView.dequeueReusableCell(withIdentifier: "humanCell") as? NewHumanCell {
                    
                    cell.objectID = human.owner!
                    print(cell.objectID)
                    //Will add human stuff later
                    
                    //return cell
                    return cell
                }
            } else if type == "animal"{
                
                if let animal = object as? Animal,
                    let cell = tableView.dequeueReusableCell(withIdentifier: "animalCell") as? NewAnimalCell {
                    
                    cell.captionLabel.text = animal.caption!
                    
                    //Will add element stuff later
                    
                    //return cell
                    return cell
                }
            } else {
                return UITableViewCell()
            }
            return UITableViewCell()
        }

    }
 
    
    //
    // news Indicator Function=>
    //
    func makenewsIndicator() {
        view.addSubview(newsIndicator)
        newsIndicator.translatesAutoresizingMaskIntoConstraints = false
        newsIndicator.hidesWhenStopped = true
        newsIndicator.color = UIColor.darkGray
        let horizontalConstraint = NSLayoutConstraint(item: newsIndicator, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        view.addConstraint(horizontalConstraint)
        let verticalConstraint = NSLayoutConstraint(item: newsIndicator, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        view.addConstraint(verticalConstraint)
    }

}















