# Uber-for-X driver & customer apps using HyperTrack SDK

**🛑WARNING: THIS SAMPLE APPLICATION IS DEPRECATED - IT ISN'T WORKING. WE'RE WORKING ON AN IMPROVED PLATFORM AND PLAN TO UPDATE THIS REPO AS SOON AS POSSIBLE.**

[Please cast your vote](https://hypertrack.canny.io/feature-requests/p/update-sample-apps-to-new-v3-architecture) if you would like to use this sample app and we'll prioritize it accordingly.

-------

Uber’s business model has given rise to a large number of Uber-for-X services. Among other things, X equals moving, parking, courier, groceries, flowers, alcohol, dog walks, massages, dry cleaning, vets, medicines, car washes, roadside assistance and marijuana. Through these on-demand platforms, supply and demand are aggregated online for services to be fulfilled offline.

This open source repo/s uses HyperTrack SDK for developing real world Uber-like consumer & driver apps.

 - **Uber-for-X Consumer app** can be used by customer to :
      - Login/signup customer using Firebase phone-number authentication
      - Show available cars near customer's current location
      - Allow customer to select pickup and dropoff location
      - Show estimated fare and route for selected pickup and dropoff location
      - Book a ride from desired pickup and dropoff location
      - Track driver to customer's pickup location
      - Track the ongoing ride to dropoff location
      - Let customers share live trip with friends and family
      - Show trip summary with distance travelled
      
<p align="center">
 <a href="https://www.youtube.com/watch?v=1qMFP5w32GY">
  <img src="http://res.cloudinary.com/hypertrack/image/upload/v1525329669/customer.png" width="300"/>
 </a>
</p>


- **Uber-for-X Driver app** can be used by driver to :
     - Login/signup driver using Firebase phone-number authentication
     - Find new rides
     - Accept a ride
     - Track and navigate till customer's pickup location, and mark the pickup as complete
     - Track and navigate from customer's pickup to dropoff location, and mark the dropoff as complete
     - Show trip summary with distance travelled
     
<p align="center">
 <a href="https://www.youtube.com/watch?v=3R9GDQitt40">
  <img src="http://res.cloudinary.com/hypertrack/image/upload/v1525329669/driver.png" width="300"/>
 </a>
</p>


## How to Begin

### 1. Get your keys
 - [Signup](https://dashboard.hypertrack.com/signup?utm_source=github&utm_campaign=uber_for_x_iOS) to get your [HyperTrack API keys](https://dashboard.hypertrack.com/settings)

### 2. Set up consumer & driver app
```bash
# Clone this repository
$ git clone https://github.com/hypertrack/uber_for_x_iOS.git

# Go into the repository
$ cd uber_for_x_iOS/RideSharingApp

# Install dependencies
$ pod install
```

- Open RideSharingApp.xcworkspace
- Add the publishable key to initialHyperTrackSetup() function in UserSampleApp AppDelegate.swift file and DriverSampleApp AppDelegate.swift file
```swift
HyperTrack.initialize("YOUR_PUBLISHABLE_KEY")
```
- Change the bundle identifiers of both apps as per your requirements.

### 3. Set up Firebase Realtime Database
 - Setup Firebase Realtime Database. For detail steps refer following link https://firebase.google.com/docs/ios/setup
 - Both Apps uses Firebase Phone Authentication. Complete the setup for same. https://firebase.google.com/docs/auth/ios/phone-auth

 - Note that Firebase Realtime Database is _not required_ to use HyperTrack SDK. You may have your own server that is connected to your apps


### 4. Tracking

- In these samples apps, Driver app creates actions for pickup and drop, which are tracked by Driver & Consumer apps.

## Documentation
For detailed documentation of the APIs, customizations and what all you can build using HyperTrack, please visit the official [docs](https://www.hypertrack.com/docs).

## Contribute
Feel free to clone, use, and contribute back via [pull requests](https://help.github.com/articles/about-pull-requests/). We'd love to see your pull requests - send them in! Please use the [issues tracker](https://github.com/hypertrack/uberx-android/issues) to raise bug reports and feature requests.

We are excited to see what live location feature you build in your app using this project. Do ping us at help@hypertrack.com once you build one, and we would love to feature your app on our blog!

## Support
Join our [Slack community](https://join.slack.com/t/hypertracksupport/shared_invite/enQtNDA0MDYxMzY1MDMxLTdmNDQ1ZDA1MTQxOTU2NTgwZTNiMzUyZDk0OThlMmJkNmE0ZGI2NGY2ZGRhYjY0Yzc0NTJlZWY2ZmE5ZTA2NjI) for instant responses, or interact with our growing [community](https://community.hypertrack.com). You can also email us at help@hypertrack.com.
