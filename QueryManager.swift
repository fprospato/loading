//
//  QueryManager.swift
//  
//
//  Created by Pavel Popov on 13.09.17.
//
//

import Foundation

//my contact
//xwoofer@yandex.ru

class QueryManager {
    
    //this is public method
    func loadNews(completionHandler: @escaping (_ queryObjects: [QueryObject], _ newsCount: Int) -> Void) {
        
        //the important thing is to be sure that we will return all data in main queue
        //so our table controller will not know of any queue, it will just get the data, or nothing
        
        loadNewsInBackground() { queryObjects, count in
            
            print("going back to main queue")
            
            let arrayOfObjects = queryObjects ?? []
            DispatchQueue.main.async {
                
                completionHandler(arrayOfObjects, count)
            }
        }
    }
    
    //this is private method
    private func loadNewsInBackground(completionHandler: @escaping (_ queryObjects: [QueryObject]?, _ newsCount: Int) -> Void) {

        //let's print each step to debug
        print("Query Followers")
        
        guard let id = PFUser.current()?.objectId else {
            print("No user id, nothing to query")
            
            completionHandler(nil, 0) //nil objects and 0 news
            return
        }
        
        //start finding followers

        let followQuery = PFQuery(className: "Follow")
        followQuery.whereKey("follower", equalTo: id)
        
        followQuery.findObjectsInBackground { [weak self](objects, error) in
            
            //guard statement makes gode more readable
            guard let followers = objects else {
                
                //maybe print error to debug
                print(error)
                
                completionHandler(nil, 0) //nil objects and 0 news
                return
            }
            
            print("We got followers objects")
            
            var followersArray = [String]()
            
            for follower in followers {
                
                //now we will use separated methods to fetch other stuff
                
                //but first let's check if current follower contains an object for key "following"
                guard let value = follower.object(forKey: "following") as? String else{
                    //just go to the next object
                    print("Current follower is not following anyone, or the value is not a String")
                    continue
                }
                
                //BTW, are you sure that value for key "following" contains correct IDs? Just asking
                followersArray.append(value)
            }
            
            //check if current user has an ID, otherwise just don't add it
            if let currentUser = PFUser.current()?.objectId {
                followersArray.append(currentUser)
            }
            
            //check that our array is not empty
            guard !followersArray.isEmpty else {
                
                print("An array of followers is empty")
                completionHandler(nil, 0) //nil objects and 0 news
                return
            }
            
            //ok, so now we are ready to get news
            //use separated method
            self?.queryNews(followersArray: followersArray, completionHandler: completionHandler)
        }
    }
    
    //private func for query news
    private func queryNews(followArray: [String], completionHandler: @escaping (_ queryObjects: [QueryObject]?, _ newsCount: Int) -> Void) {
        
        print("Query news from \(followArray)")
        
        //making temp array
        var temporaryArray: [QueryObject] = []
        
        //getting related news post
        let newsQuery = PFQuery(className: "News")
        newsQuery.whereKey("user", containedIn: followArray) //find this info from who we're following
        newsQuery.limit = 30
        newsQuery.addDescendingOrder("createdAt") //get most recent
        newsQuery.findObjectsInBackground(block: { [weak self](objects, error) in
            
            //same thing, use guard instead
            //guard statement makes gode more readable
            guard let news = objects else {
                
                //maybe print error to debug
                print(error)
                
                completionHandler(nil, 0) //nil objects and 0 news
                return
            }
        
            print("We got news objects")

            //ok, no we need to go in separated method, for making code save its beaty
                
            parseNews(from: news) { objects in
                
                print("We got all data")
                
                //return values now
                completionHandler(objects, news.count)
            }
        })
    }
    
    private func parseNews(from objects: [PFObject], completionHandler: @escaping (_ queryObjects: [QueryObject]) -> Void) {
        
        print("Parsing news from \(objects)")
        //here is the fix which should help
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            //making temp array
            var temporaryArray: [QueryObject] = []
            
            //now the important thing
            //we need to create a dispatch group to make it possible to load all additional data before updating the table
            //NOTE! if your data are large, maybe you need to show some kind of activity indicator, otherwise user won't understand what is going on with the table
            
            let dispathGroup = DispatchGroup()
            
            for object in objects {
                
                //detecting the type of the object
                guard let type = object.value(forKey: "type") as? String,  let id = object.value(forKey: "id") as? String else{
                    //wrong value or type, so don't check other fields of that object and start to check the next one
                    print("=The type or id not found or it is not a String=")
                    print(object.value(forKey: "type"))
                    print(object.value(forKey: "id"))
                    print("================================================")
                    continue
                }
                
                let date = object.createdAt
                
                //so now we can check the type and create objects
                
                //and we are entering to our group now
                dispathGroup.enter()
                print("We entered the group with object id - \(id), type \(type)")

                //now let's parse it
                self?.parseType(type, id: id, createdAt: date) { object in
                    
                    if let unwrappedObject = object {
                        
                        print("object with id \(id) was added to temporaryArray")
                        
                        temporaryArray.append(unwrappedObject)
                    }else{
                        print("objects with id \(id) was not added. It is nil")
                    }
                    //don't forget to leave the dispatchgroup
                    dispathGroup.leave()
                }
            }
            
            //we need to wait for all tasks entered the group
            //you can also add a timeout here, like: user should wait for 5 seconds maximum, if all queries in group will not finished somehow
            dispathGroup.wait()
            
            //so we finished all queries, and we can return finished array
            completionHandler(temporaryArray)
        }
    }
    
    private func parseType(_ type: String, id: String, createdAt: NSDate, completionHandler: @escaping (_ queryObject: QueryObject?) -> Void) {
        
        switch type {
        case "animal":
            //now we will make a query for that type
            self.queryAdditionalClass(name: "Animals", id: id, completionHandler: { (name, caption) in
                
                print("An animal query finished")
                //I've added a check for those parameters, and if they are nil, I won't add that objects to the table
                //but you can change it as you wish
                if let objectName = name, let objectCaption = caption {
                    //now we can create an object
                    
                    let newAnimal = Animal()
                    newAnimal.id = id
                    newAnimal.date = createdAt
                    
                    print("Animal was created")
                    completionHandler(newAnimal)
                    
                }else{
                    print("Animal query for id - \(id) is failed. Name - \(name), caption - \(caption)")
                    completionHandler(nil)
                }
                
            })
        case "human":
            
            //same for Human
            self.queryAdditionalClass(name: "Human", id: id, completionHandler: { (name, caption) in
                
                print("A human query finished")
                
                if let objectName = name, let objectCaption = caption {
                    let newHuman = Human()
                    newHuman.id = id
                    newHuman.date = createdAt
                    
                    print("Human was created")
                    completionHandler(newHuman)
                    
                }else{
                    print("Human query for id - \(id) is failed. Name - \(name), caption - \(caption)")
                    completionHandler(nil)
                }
                
            })
        case "elements":
            
            //same for Element
            self.queryAdditionalClass(name: "Element", id: id, completionHandler: { (name, caption) in
                
                print("Element query finished")
                if let objectName = name, let objectCaption = caption {
                    let newElement = Element()
                    newElement.id = id
                    newElement.date = createdAt
                    completionHandler(newElement)
                    
                    print("Element was added to array")
                    
                }else{
                    print("Element query for id - \(id) is failed. Name - \(name), caption - \(caption)")
                }
                
            })
        default:
            //unrecognized type
            //don't forget to leave the dispatchgroup
            print("Unrecognized type, returning nil")
            completionHandler(nil)
        }
    }
    
    //the method for making query of an additional class
    private func queryAdditionalClass(name: String, id: String, completionHandler: @escaping (_ name: String?, _ caption: String?) -> Void) {
        
        print("Starting query additional class - \(name)")
        let query = PFQuery(className: name)
        query.whereKey("objectId", equalTo: id)
        query.limit = 1
        query.findObjectsInBackground(block: { (objects, error) in
            
            if let object = objects?.first {
                
                let name =  object.object(forKey: "type") as? String
                let caption = object.object(forKey: "caption") as? String
                
                completionHandler(name, caption)
                
            }else{
                print(error?.localizedDescription ?? "Additional object with id \(id) not found")
                
                completionHandler(nil, nil)
            }
        })
        
    }

}
