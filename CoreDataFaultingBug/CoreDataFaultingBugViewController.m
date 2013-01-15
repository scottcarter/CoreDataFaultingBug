//
//  CoreDataFaultingBugViewController.m
//  CoreDataFaultingBug
//
//  Created by Scott Carter on 1/15/13.
//  Copyright (c) 2013 Scott Carter. All rights reserved.
//

#import "CoreDataFaultingBugViewController.h"


/*
 
 This project is intended to show that the following call has no effect on a fetch 
 from Core Data and that objects are faulted:
 
 setReturnsObjectsAsFaults:NO
 
 
 Accessing a property on a returned object in this case fires the fault (not expected).
 
 The reponse to isFault on a returned object is YES (expecting NO).
 
 
 Steps to reproduce problem:
 
 1. Run the simulator and click "Create DB".
 
 2. Stop the simulator.
 
 3. Run the simulator and click "Fetch".
 
 
 */


// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                    Private Interface
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//


@interface CoreDataFaultingBugViewController ()


// ==========================================================================
// Properties
// ==========================================================================
//
#pragma mark -
#pragma mark Properties

@property (nonatomic, strong) UIManagedDocument *contactDatabase;  // Model is a Core Data database of contacts


@end



// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                    Implementation
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
#pragma mark -

@implementation CoreDataFaultingBugViewController


// ==========================================================================
// Constants and Defines
// ==========================================================================
//
#pragma mark -
#pragma mark Constants and Defines

// Contact Database Name
#define CONTACT_DATABASE_NAME @"_Contact_Database"



// ==========================================================================
// Synthesize private properties
// ==========================================================================
//
#pragma mark -
#pragma mark Synthesize private properties

@synthesize contactDatabase = _contactDatabase;



// ==========================================================================
// Initializations
// ==========================================================================
//
#pragma mark -
#pragma mark Initializations

// Callback for fetch of managed document
- (void)readyWithDocument:(UIManagedDocument *)managedDocument
{
    self.contactDatabase = managedDocument;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	
    
    
    // Get our managed document.
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:CONTACT_DATABASE_NAME]; // url is now "<Documents Directory>/documentName
    
    UIManagedDocument *managedDocument = [[UIManagedDocument alloc] initWithFileURL:url];
    
    
    NSLog(@"Created document %@",CONTACT_DATABASE_NAME);
    
    
    // Does not exist on disk, so create it
    if (![[NSFileManager defaultManager] fileExistsAtPath:[managedDocument.fileURL path]]) {
        NSLog(@"Document did not exist on disk, so we are creating");
        [managedDocument saveToURL:managedDocument.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            [self readyWithDocument:managedDocument];
        }];
    }
    
    // Exists on disk, but we need to open it
    else if (managedDocument.documentState == UIDocumentStateClosed) {
        NSLog(@"Document existed on disk and needs to be opened");
        [managedDocument openWithCompletionHandler:^(BOOL success) {
            [self readyWithDocument:managedDocument];
        }];
    }
    
    // Already open and ready to use
    else if (managedDocument.documentState == UIDocumentStateNormal) {
        NSLog(@"Document is already open and ready for use");
        [self readyWithDocument:managedDocument];
    }
    
    else if (managedDocument.documentState == UIDocumentStateInConflict) {
        NSLog(@"ERROR: Got UIDocumentStateInConflict");
    }
    
    else if (managedDocument.documentState == UIDocumentStateSavingError) {
        NSLog(@"ERROR: Got UIDocumentStateSavingError");
    }
    
    else if (managedDocument.documentState == UIDocumentStateEditingDisabled) {
        NSLog(@"ERROR: Got UIDocumentStateEditingDisabled");
    }
    
    else {
        NSLog(@"ERROR: Other documentState = %d",managedDocument.documentState);
    }
    
    


}


// ==========================================================================
// Actions
// ==========================================================================
//
#pragma mark -
#pragma mark Actions



- (IBAction)CreateDatabaseAction:(UIButton *)sender {
    [self createDatabase];
}


- (IBAction)DeleteDatabaseAction:(UIButton *)sender {
    [self deleteDatabase];
}



- (IBAction)FetchRequestAction:(UIButton *)sender {
    [self fetchRequest];
}



// ==========================================================================
// Methods
// ==========================================================================
//
#pragma mark -
#pragma mark Methods


// Populate a database
- (void)createDatabase
{
    
    // Create some entities and populate with test data.
    for(int i=0; i<10; i++) {
        
        Person *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:self.contactDatabase.managedObjectContext];

        person.firstName = @"John";
        person.lastName = @"Smith";
    }
    
    
     [self.contactDatabase saveToURL:self.contactDatabase.fileURL
                   forSaveOperation:UIDocumentSaveForOverwriting
                  completionHandler:^(BOOL success) {
                      if(!success){
                          NSLog(@"ERROR: Failed to save document %@", self.contactDatabase.localizedName);
                      } else {
                          
                          NSLog(@"Completed createDatabase.  Save has completed successfully.");
                      }
                  }];
}



// Remove the persistent store for our context and delete the associated file on disk.
//
- (void)deleteDatabase
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.contactDatabase.managedObjectContext;
    
    // Retrieve the store URL
    NSURL * storeURL = [[managedObjectContext persistentStoreCoordinator] URLForPersistentStore:[[[managedObjectContext persistentStoreCoordinator] persistentStores] lastObject]];
    
    
    [managedObjectContext lock];  // Lock the current context
    
    
    // Remove the store from the current managedObjectContext
    if ([[managedObjectContext persistentStoreCoordinator] removePersistentStore:[[[managedObjectContext persistentStoreCoordinator] persistentStores] lastObject] error:&error])
    {
        // Remove the file containing the data
        if(![[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]){
            NSLog(@"Could not remove persistent store file");
        }
        
        // Recreate the persistent store
        if(![[managedObjectContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]){
            NSLog(@"Could not add persistent store");
        }
    }
    
    else {
        NSLog(@"Could not remove persistent store");
    }
    
    [managedObjectContext reset];
    [managedObjectContext unlock];
    
    NSLog(@"Completed deleteDatabase");
}


// Perform a fetch request to demonstrate that
// setting setReturnsObjectsAsFaults:NO has no effect.
- (void)fetchRequest
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
    
    
    // We don't want faults.
    //
    // According to the documentation:
    // If NO, the objects returned from the fetch are pre-populated with their property values
    // (making them fully-faulted objects, which will immediately return NO if sent the isFault message).
    //
    [request setReturnsObjectsAsFaults:NO];

        
    NSError *error = nil;
    NSArray *personRecordArr = [self.contactDatabase.managedObjectContext executeFetchRequest:request error:&error];
    
    if(error){
        NSLog(@"Error: %@",error.localizedDescription);
        return;
    }
    
    if(!personRecordArr) {
        NSLog(@"Error: personRecordArr is nil");
        return;
    }
    
    if([personRecordArr count] == 0){
        NSLog(@"Warning: Please use Create DB button to populate some data. Stop and Restart the simulator before using Fetch");
        return;
    }
    
    
    // Get one of the Person objects
    Person *person = [personRecordArr objectAtIndex:0];
    
    // I would expect the result of the following test to be "object is NOT a fault"
    // This is not what I get.
    if([person isFault]){
        NSLog(@"object is fault");
    }
    else {
        NSLog(@"object is NOT a fault");
    }
    
    // This causes a firing of the fault, which is not expected.
    NSLog(@"person.firstName = %@",person.firstName);
}


@end
