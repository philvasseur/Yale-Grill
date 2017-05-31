//Imports the Firebase Cloud Functions and Firebase Admin SDKs
const functions = require('firebase-functions');
const admin = require('firebase-admin');
//Initializes the admin SDK
admin.initializeApp(functions.config().firebase);

//Defines the sendPushNotification function to be called every time the path below is written to
exports.sendPushNotification = functions.database.ref('/Grills/{grillID}/Orders/{orderID}')
    .onWrite(event => {

    	//Checks that the data isn't null, has changed, and that the order state is 2 (meaning ready)
    	//If any of these are false, returns.
    	if(!event.data.exists() || !event.data.changed() || event.data.val().orderStatus != 2) {
    		console.log("No Action Taken");
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
	    console.log(payload.notification.body);

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