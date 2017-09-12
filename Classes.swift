//
//  Classes.swift
//  FeedTester
//
//  Created by Francesco Prospato on 9/12/17.
//  Copyright © 2017 Francesco Prospato. All rights reserved.
//

import Foundation

class QueryObject {
    var id: String?
    var date: Date? //change of your date for object.createdAt has different type
    //var caption: String?
    var owner : String?
    var ownerFullname : String?
    var ownerProfilePic : UIImage?
    var name: String?
    //var type: String? //use this var you don't need to have subclasses
}

//If your subclasses will not have unique parameters, you can left only one class QueryObject, without subclasses
//In this case just uncomment the "type" variable in the QueryObject, then you can check that var in cellForRowAt
class Element: QueryObject {
    var objectID : String?
    var userID : String?
    var elementType : String?
}

class Human: QueryObject {
    var objectID : String?
    var following : String?
}

class Animal: QueryObject {
    var objectID : String?
    var caption: String?
    var userID : String?
    var animalType : String?
}
