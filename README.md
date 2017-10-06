<h3 align="center">
  <img src="https://user-images.githubusercontent.com/10122678/31050613-65d8e7aa-a61d-11e7-9b5a-c163cf1e2177.png" />
</h3>


# Yale Grill

Yale Grill is an iOS application that streamlines the grill ordering process at Yale Dining Halls.

Only usable by those with a valid Yale email address.

## Features

* Keeps track of and updates the order using Google Firebase's Realtime Database and Authentication.
* Uses Google Signin, allowing only students with Yale emails to access the app and place orders.
* Predetermined accounts allow cooks to see orders and give updates on them as they are prepared.
* Uses Google Firebase's Cloud Functions and Cloud Messaging to send push notifications when the order is ready for pickup, lowering the amount of food wasted by students forgetting to pickup their orders.
* A strike is given when a student doesn't pick up their order within a set amount of time, temporarily banning the user from if they reach a set amount of strikes (which stops any possible griefing).
* Uses location services to automatically suggest the dining hall which you are closest to.


## Credits

**Authors:** Created and Designed by *Philip Vasseur*

**Library Resources**
* [Firebase](https://firebase.google.com)

---

###### Copyright © 2017 Philip Vasseur. All rights reserved.
