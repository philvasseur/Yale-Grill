//Imports the Firebase Cloud Functions and Firebase Admin SDKs
const functions = require('firebase-functions');
const admin = require('firebase-admin');

//Initializes the admin SDK
admin.initializeApp(functions.config().firebase);

//Defines the sendPushNotification function to be called every time the path below is written to
exports.sendPushNotification = functions.database.ref('/Grills/{grillID}/Orders/{orderID}')
    .onWrite(event => {

    	
    	if (!event.data.exists()) { //Checks that order exists (onWrite is called by deletions), if not returns
    		console.log("No Data Exists (Order Deleted) - No Action Taken");
    		return;
    	} if(event.data.val().orderStatus != 2) { //Checks that orderStatus is 2 (ready status), if not returns
    		console.log("OrderStatus not set to ready - No Action Taken");
      		return;
    	} else if (!event.data.val().pushToken) { //Checks that a pushToken exists, if not returns
    		console.log("PushToken does not exist (DB/Client Error ??) - No Action Taken");
    		return;
    	}
	    
	    //Creates the payload for the notification
	    let payload = {
            notification: {
                title: 'Hey !',
                body: "Your Food is Ready!",
                sound: 'default',
                badge: '1'
            }
        };

        let token = event.data.val().pushToken;

	    console.log('Notifying token: ',token);

	    //admin.messaging().sendToDevice([token],payload);
	    return admin.messaging().sendToDevice([token], payload).then(response => {
	        //check if there was an error.
	        const error = response.results[0].error;
	        if (error) {
	        	console.error('Failure sending notification to', token, error);
	        }
	        return;
      	});

    });