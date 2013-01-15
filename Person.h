//
//  Person.h
//  CoreDataFaultingBug
//
//  Created by Scott Carter on 1/15/13.
//  Copyright (c) 2013 Scott Carter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Person : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;

@end
