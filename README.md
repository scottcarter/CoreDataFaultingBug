This project is intended to show that the following call has no effect on a fetch 
 from Core Data and that objects are faulted:
 
 setReturnsObjectsAsFaults:NO
 
 
 Accessing a property on a returned object in this case fires the fault (not expected).
 
 The reponse to isFault on a returned object is YES (expecting NO).
 
 
 Steps to reproduce problem:
 
 1. Run the simulator and click "Create DB".
 
 2. Stop the simulator.
 
 3. Run the simulator and click "Fetch".
 
 
