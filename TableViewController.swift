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
        var newsLeftNumber = 0

        //let's use our manager
        let manager = QueryManager()
        
        activityIndicator.startAnimating()
        manager.loadNews() { [weak self] queryObjects, newsCount in
            
            tableObjects = queryObjects
            newsLeftNumber = newsCount
            
            self?.activityIndicator.stopAnimating()
            self?.tableView.reloadData()
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















