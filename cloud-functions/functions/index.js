//Imports the Firebase Cloud Functions and Firebase Admin SDKs
const functions = require('firebase-functions');
const admin = require('firebase-admin');

//Initializes the admin SDK
admin.initializeApp(functions.config().firebase);

//Defines the sendPushNotification function to be called every time the path below is written to
exports.sendPushNotification = functions.database.ref('/Grills/{grillID}/Orders/{orderID}').onWrite(event => {
	if (!event.data.exists()) { //Checks that order exists (onWrite is called by deletions), if not returns
		console.log("No Data Exists (Order Deleted) - No Action Taken");
		return;
	} if(event.data.val().orderStatus != 2) { //Checks that orderStatus is 2 (ready status), if not returns
		console.log("OrderStatus not set to ready - No Action Taken");
  		return;
	} else if (!event.data.val().pushToken) { //Checks that a pushToken exists, if not returns
		console.error("PushToken does not exist (DB/Client Error ??) - No Action Taken");
		return;
	}
    
    //Creates the payload for the notification
    let payload = {
        notification: {
            title: 'Hey!',
            body: "Your Food is Ready!",
            sound: 'default',
            badge: '1'
        }
    };

    let token = event.data.val().pushToken;
    console.log('Notifying token: ',token);
    return admin.messaging().sendToDevice([token], payload).then(response => {
        //check if there was an error.
        const error = response.results[0].error;
        if (error) {
        	console.error('Failure sending notification to', token, error);
        }
        return;
	});
});

//Defines the orderNumCounter function to be called everutime an order is written to. Function increments orderNum and sets order numbers.
exports.orderNumCounter = functions.database.ref('/Grills/{grillID}/Orders/{orderID}').onWrite((event) => {
	var countRef = event.data.ref.parent.parent.child('OrderNumCount');
		//Uses transactions in the case of multiple orders placed at the same time.
		var count;
	    countRef.transaction(function(current) {
	    	//If it exists now, but didn't before, it means the order was just added.
	        if (event.data.exists() && !event.data.previous.exists()) {
	            var newCount = (parseInt(current) || 0) +1;
		    	if(newCount >= 100) {
		    		newCount = 1;
		    	}
		   		count = newCount;
		    	return newCount;
	        }	
	        return current;
		}).then(()=>{
			if(event.data.exists()) {
				admin.database().ref('/Orders/'+event.params.orderID+'/orderNum').set(count);
			}
		});
});
