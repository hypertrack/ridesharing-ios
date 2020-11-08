# Build ridesharing driver & rider apps using HyperTrack SDK

<p align="center">👉 <a href="https://github.com/hypertrack/ridesharing-android">Looking for the Android version?</a></p>


## Introduction

We have now entered the second decade of a large variety of on-demand logistics services, such as ridesharing, gig work and on-demand delivery.

These on-demand logistics services include moving, parking, courier, groceries, flowers, dog walks, massages, dry cleaning, vets, medicines, car washes, roadside assistance, cannabis and more.

Through these on-demand platforms, supply and demand are aggregated online for services to be fulfilled offline.

## Creating a ridesharing solution

Learnings from building a ridesharing solution can be applied to many of the on-demand logistics services listed above.

A customer requests a pick up at a location chosen by the customer. The pickup order is dispatched to drivers who are available within an area of reach. One of the drivers picks up the customer's request and proceeds to the customer's location for a pick up. Once the pick up takes place, the driver will transport the customer to a destination chosen by the customer.

<p align="center">
  <img src="Images/Demo.gif" alt="Apps demo"/>
</p>

### On-demand solution steps

We will go through the following steps:

* [Customer order](#customer-order): Customer books an order from desired pickup and drop off location
* [Driver registration](#driver-registration): Driver registers with on-demand logistics backend
* [Locate nearby drivers](#locate-nearby-drivers): Customer's request is matched with nearest drivers available
* [Assign and accept order](#assign-and-accept-order): Customer's request assigned to avaiable drivers and is accepted
* [Track driver to customer's pickup location](#track-driver-to-customer-pickup-location): Create driver tracking experience for the customer
* [Track the ongoing order to drop off location](#track-ongoing-order-to-drop-off-location): Track live location of customer going to the drop off location
* [Share tracking updates](#share-tracking-updates): Enable the customer share whereabouts with friends and family
* [Generate order summary](#generate-order-summary): Generate and share order summary for billing and record-keeping purposes

## On-demand solution components

Before we proceed to go through the steps required to create an on-demand solution, we need to build the following components:

* Customer app
* Driver app
* On-demand logistics backend

### Customer app

Customer app is a mobile app which helps achieve the following:

<p align="center">
 <a href="https://www.youtube.com/watch?v=1qMFP5w32GY">
  <img src="http://res.cloudinary.com/hypertrack/image/upload/v1525329669/customer.png" width="300"/>
 </a>
</p>

- Displaying nearby drivers as an option offered to the customer.
- Order request that can be sent to the on-demand logistics backend
- Tracking driver to the customer's pickup location. To achieve this, the customer's app uses [Views SDK](/docs/guides/stream-data-to-native-apps) to provide real-time location updates to the customer
- Track customer's trip to the customer's destination. The customer's app uses [Views SDK](/docs/guides/stream-data-to-native-apps) to provide real-time location updates to the customer
- Display trip summary to the customer after the trip completion. This is done with [Views SDK](/docs/guides/stream-data-to-native-apps)

#### Important note

Customer app does **not** track location of the customer. No location permissions are necessary to be requested from the customer to support the tracking experience.

### Driver app

Driver app is another mobile app which helps achieve the following:

<p align="center">
 <a href="https://www.youtube.com/watch?v=3R9GDQitt40">
  <img src="http://res.cloudinary.com/hypertrack/image/upload/v1525329669/driver.png" width="300"/>
 </a>
</p>

- Driver registration and authentication with your on-demand logistics backend
- Displaying assigned order request to the driver
- Order request acceptance
- Generating location data for the customer to track the driver to both pickup destination as well as to drop off destination
- Pickup and drop off order completion and sign off

#### Important note

Driver app **tracks** the driver. Location and motion permissions are necessary to be requested from the driver to track an order.

### On-demand logistics backend

On-demand logistics backend is built to achieve the following:

- Customer and driver registration and management
- Customer order requests
- Find nearby drivers and assign customer order requests with [Nearby API](#making-a-request-to-get-nearby-drivers)
- Receive driver acceptance for orders
- Manage trips to customer's pickup and drop off locations with [Trips API](/docs/references#references-apis-trips)

## Customer order

On-demand customer downloads and installs the [customer app](#customer-app) and signs in. Customer can use the app to book an order.

### Customer registration

Your customer app and on-demand logistics backend implement customer registration by capturing customer's identity and verifying customer's credentials. You store customer's information in your on-demand logistics backend. The customer's identity and credentials are used to authenticate customer's order request and present to assigned drivers.

### Order execution

The customer picks a location and orders a pickup to go to a destination. The on-demand logistics backend receives the order and stores it in its database for the next step. This step will involve finding available drivers near pickup location as explained below.

## Driver registration

The driver downloads the [driver app](#driver-app), registers and authenticates to your on-demand logistics backend. In the process of registration, driver app captures driver's `device_id` from HyperTrack SDK which is sent to on-demand logistics backend along with the driver's identity and credentials.

To add location tracking to your on-demand solution, you must add HyperTrack SDK to your driver app. Please use one of the following options.

### Enable location tracking in driver app

Follow these instructions to install the SDK.

- [Android SDK](/docs/install-sdk-android)
- [iOS SDK](/docs/install-sdk-ios)
- [Flutter SDK](/docs/install-sdk-flutter)
- [React Native SDK](/docs/install-sdk-react-native)

### Identify drivers

In order to provide a great on-demand experience for customers, add driver identity as the name for your driver's device. The driver's name will show in your customer's app.

Review instructions on how to set [device name and metadata](/docs/guides/setup-and-manage-devices#setting-device-name-and-metadata) and make a decision on what works best for your on-demand app.

For example, the device name can be a driver's name or some other identifier you use in your system with example below:

```shell script
{
  "name": "Kanav",
  "metadata": {
    "model": "i3",
    "make": "BMW",
    "color": "blue"
  }
}
```

## Locate nearby drivers

Live location is an important input to the driver dispatch algorithm to request a pickup and dropoff. 

For further details, documentation and code examples, please review [Nearby API guide](/docs/guides/dispatch-work-to-nearby-devices).

Nearby API locates app users on demand, figures out which ones are nearest to the location of interest, and returns them as an ordered list with nearest first. 

### Make a request to get nearby drivers

First, use this POST [Nearby API](/docs/references#references-apis-nearby-api) request to find available drivers near pickup location.

>POST&nbsp&nbsp&nbsp`https://v3.api.hypertrack.com/devices/nearby`

Nearby API HTTP POST uses a payload structure like this below.

```shell script
{
	"location": {
		"coordinates": [
          -122.402007, 37.792524
        ],
		"type" : "Point"
    },
    "radius" : 1000,
    "metadata": {
        "gig_type": "ridesharing",
        "order": "rider_A_pickup_at_location_X"
    }
}
```

In the above payload example `location` and `radius` of represent a circular area of 2km in diameter centered at a gig location `-122.402007, 37.792524` within which devices are considered nearby.

The `metadata` parameter is optional to apply filtering (e.g only looking for devices within a city/region)
In place of `metadata`, filtered list of device_ids can also be be provided directly via `devices` parameter as shown below.

```shell script
{
	"location": {
		"coordinates": [
          -122.402007, 37.792524
        ],
		"type" : "Point"
    },
    "radius" : 1000,
    "devices":[
      "00112233-531B-4FC5-AAC5-3DB7886FE3D2",
      "00112233-E0A7-4217-8175-888CA30C5225"
      ]
}
```
    
Upon making request with above payload, you will get an HTTP 202 response with the below payload like this below.

### Return response data

Nearby API POST request returns a response that contains `request_url` string. This is the Nearby API GET call you need to invoke to obtain nearby devices.

```shell script
{
    "request_url": 'https://v3.api.hypertrack.com/devices/nearby?request_id=09f63b10-9bbc-4b24-af1a-d8ac84644fcc&limit=100'}
}
```
### Fetch request results

In order to fetch nearby devices corresponding to the above request, make a GET request to the above `request_url` sent in POST API response.

>GET&nbsp&nbsp&nbsp`https://v3.api.hypertrack.com/devices/nearby?request_id={request_id}&limit={limit}&{pagination_token}`

Parameters `limit` and `pagination_token` are optional to paginate the response.

Upon making the above request, you will get an HTTP 200 response with this below payload. Make a note of `status` field which indicates whether the request is in `pending` or `completed` status.

```shell script
{
   "data":[
      {
         "device_info":{
            "device-model":"IPhone X",
            ...
         },
         "metadata":{
            "key_1":"value_1"
         },
         "location":{
            ...
            "geometry":{
               "coordinates":[
                  35.10654,
                  47.847252,
                  610
               ],
               "type":"Point"
            },
            ... 
         },
         ...
         "nearby_devices_request_id":"09f63b10-9bbc-4b24-af1a-d8ac84644fcc",
         "device_id":"00112233-FFA6-404C-A30F-27B38836A887",
         ... 
      }
   ],
   "status":"pending"
}

```

Here `data` is the list of devices which are ranked based on their distance from gig location (nearest first). You may poll this GET `request_url` as additional devices are found and identified nearby.

### Receiving request completion notification

In addition to GET /devices/nearby API, you will also get notified about the completion of a request via webhook notification with below payload example structure.

```shell script
 {
    "created_at": "2020-04-29T02:25:59.906839Z",
    "type": "nearby_devices_request",
    "data": {
        "value": "completed",
        "request_id": "09f63b10-9bbc-4b24-af1a-d8ac84644fcc",
        "location": {
                "coordinates": [
                  -122.402007, 37.792524
                ],
                "type" : "Point"
            },
        "metadata": {
            "team": "san_francisco",
            "gig_type": "delivery"
        }
        "radius": 1000
    },
    'version': '2.0.0'
 }

```

Once you receive the notification, you will be able to make a final GET `request_url` call to obtain a list of devices that HyperTrack determines to be nearby the location of interest. These are drivers that can be presented with the customer's request.

:::note
See [Nearby API guide](/docs/guides/dispatch-work-to-nearby-devices) for detailed documentation and code examples.
:::

## Assign and accept order

Once nearby available drivers located, customer's request is assigned to available drivers by your on-demand logistics backend and presented in their driver app. One of the drivers can accept the order and drive to the pickup location.

### Assign order request to available drivers

On-demand logistics backend receives results of [Nearby API](#locate-nearby-drivers) and assigns order request to the nearest available drivers. Your [driver app](#driver-app) presents the pickup order in the screen to each of these available drivers, along with the identity of the customer and pickup location.

<p align="center">
<img src="/docs/img/driver_order_presented.png" width="30%" alt="Tracking Experience"/>
</p>

### Driver acceptance

As illustrated in the image above, driver app gives an opportunity for the driver to accept an assigned order. Once the driver accepts the order, on-demand logistics backend proceeds to create a trip for the driver to the pickup location as explained below.

## Track driver to customer pickup location

Once the driver accepted the pickup order, your on-demand logistics backend proceeds to work with Trips API to create a trip for the driver to the destination at pickup location and provide a real-time tracking experience to the customer.

### Create a trip with destination at pick up location

To create driver tracking experience for the customer, create a trip with ETA to the pickup destination. Once the pickup order is accepted by the driver, inside your on-demand logistics backend, Use [Trips API](/docs/guides/track-live-route-and-eta-to-destination#create-a-trip-with-destination) to create a trip for driver.

See the code example below that creates a trip with ETA for driver's `device_id`, with pickup `destination`:

<Tabs defaultValue="js" values={[
{label: "JavaScript", value:"js"},
{label: "Python", value:"py"},
{label: "Java", value:"java"},
{label: "PHP", value:"php"},
{label: "Ruby", value:"ruby"}
]
}>

<TabItem value="js">

```js

// Instantiate Node.js helper library instance
const hypertrack = require('hypertrack')(accountId, secretKey);

let tripData = {
  "device_id": "00112233-4455-6677-8899-AABBCCDDEEFF",
  "destination": {
    "geometry": {
      "type": "Point",
      "coordinates": [35.107479, 47.856564]
    }
  }
};

hypertrack.trips.create(tripData).then(trip => {
  // Trip created
}).catch(error => {
  // Error handling
})

```

</TabItem>
<TabItem value="py">

```py
// Use HyperTrack Python library

from hypertrack.rest import Client
from hypertrack.exceptions import HyperTrackException

hypertrack = Client({AccountId}, {SecretKey})

trip_data = {
  "device_id": "00112233-4455-6677-8899-AABBCCDDEEFF",
  "destination": {
    "geometry": {
      "type": "Point",
      "coordinates": [35.10747945667027, 47.8565694654932]
    }
  }
}

trip = hypertrack.trips.create(trip_data)
print(trip)

```

</TabItem>
<TabItem value="java">

```java
OkHttpClient client = new OkHttpClient();

MediaType mediaType = MediaType.parse("application/json");
RequestBody body = RequestBody.create(mediaType,"{\n" +
        "  \"device_id\": \"00112233-4455-6677-8899-AABBCCDDEEFF\",\n" +
        "  \"destination\": {\n" +
        "    \"geometry\": {\n" +
        "      \"type\": \"Point\",\n" +
        "      \"coordinates\": [-122.3980960195712, 37.7930386903944]\n" +
        "    }\n" +
        "  }\n" +
        "}");

String authString = "Basic " +
  Base64.getEncoder().encodeToString(
    String.format("%s:%s", "account_id_value","secret_key_value")
      .getBytes()
  );

Request request = new Request.Builder()
  .url("https://v3.api.hypertrack.com/trips/")
  .post(body)
  .addHeader("Authorization", authString)
  .build();

Response response = client.newCall(request).execute();

System.out.println(response.body().string());
```

</TabItem>
<TabItem value="php">

```php
<?php

$request = new HttpRequest();
$request->setUrl('https://v3.api.hypertrack.com/trips/');
$request->setMethod(HTTP_METH_POST);

$basicAuth = "Basic " . base64_encode('{AccountId}' . ':' . '{SecretKey}');

$request->setHeaders(array(
  'Authorization' => $basicAuth
));

$request->setBody('{
    "device_id": "00112233-4455-6677-8899-AABBCCDDEEFF",
    "destination": {
        "geometry": {
            "type": "Point",
            "coordinates": [
                -122.3980960195712,
                37.7930386903944
            ]
        }
    }
}');

try {
  $response = $request->send();

  echo $response->getBody();
} catch (HttpException $ex) {
  echo $ex;
}

?>
```

</TabItem>
<TabItem value="ruby">

```ruby
require 'uri'
require 'net/http'
require 'base64'
require 'json'

url = URI("https://v3.api.hypertrack.com/trips/")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

request = Net::HTTP::Post.new(url)
request["Authorization"] = 'Basic ' + Base64.strict_encode64( '{AccountId}' + ':' + '{SecretKey}' ).chomp
request.body = {
    "device_id": "00112233-4455-6677-8899-AABBCCDDEEFF",
    "destination": {
        "geometry": {
            "type": "Point",
            "coordinates": [
                -122.3980960195712,
                37.7930386903944
            ]
        }
    }
}.to_json

response = http.request(request)
puts response.read_body
```

</TabItem>
</Tabs>

### Understanding Trips API create trip response

Once the trip is created, the Trips API responds with an active trip object that returns the original payload with additional properties.

You will get an example payload response like the one below. In the response you get estimate (route/ETA) to destination, shareable URL for customers, embed URL for ops dashboards for active ( as noted in `status` field in the response ) trip.

The `destination` object in the response will now contain `address` field which is an address that HyperTrack determines ( reverse geocodes ) based on `destination` coordinates you submitted in the trips creation request above. You can use this `address` to show the destination to the user after creating the trip.


```json title="HTTP 201 - New trip with destination"
{
   "trip_id":"2a819f6a-5bee-4192-9077-24fc61503ae9",
   "device_id":"00112233-4455-6677-8899-AABBCCDDEEFF",
   "started_at":"2020-04-20T00:57:33.484361Z",
   "completed_at":null,
   "status":"active",
   "views":{
      "embed_url":"https://embed.hypertrack.com/trips/2a819f6a-5bee-4192-9077-24fc61503ae9?publishable_key=<your_publishable_key>",
      "share_url":"https://trck.at/abcdef"
   },
   "device_info":{
      "os_version":"13.3.1",
      "sdk_version":"4.0.2-rc.5"
   },
   "destination":{
      "geometry":{
         "type":"Point",
         "coordinates":[
            -122.500005,
            37.785334
         ]
      },
      "radius":30,
      "scheduled_at":null,
      "address":"100 34th Ave, San Francisco, CA 94121, USA"
   },
   "estimate":{
      "arrive_at":"2020-04-20T01:06:45.914154Z",
      "route":{
         "distance":4143,
         "duration":552,
         "remaining_duration":552,
         "start_address":"55 Spear St, San Francisco, CA 94105, USA",
         "end_address":"100 34th Ave, San Francisco, CA 94121, USA",
         "polyline":{
            "type":"LineString",
            "coordinates":[
               [
                  -122.50385,
                  37.76112
               ],
               ...
            ]
         }
      }
   },
   "eta_relevance_data":{
      "status":true
   }
}
```

### Estimate object in Trip API response

The Trips API responds with an active trip object that returns the original payload with additional properties. HyperTrack provides estimates for every trip with a destination.

Since in the API request we specified a destination, the Trips API response will return the `estimate` object with fields are explained here as follows:

- Field `arrive_at` shows estimated time of arrival (ETA) as UTC timestamp
- Object `route` contains the following data:
  - Field `distance` shares estimated route distance (in meters)
  - Fields `duration` and `remaining_duration` share actual and remaining durations (in seconds)
  - Fields `start_address` and `end_address` display reverse geocoded place names and addresses for trip start, complete and intermediate stops (based on activity)
  - Field `polyline` contains an array of coordinates for the estimated route from the live location to the destination as polyline in GeoJSON [`LineString`](http://wiki.geojson.org/GeoJSON_draft_version_6#LineString) format. It is an array of Point coordinates with each element linked to the next, thus creating a pathway to the destination.

```json title="HTTP 201 - New trip with destination"
   "estimate":{
      "arrive_at":"2020-04-20T01:06:45.914154Z",
      "route":{
         "distance":4143,
         "duration":552,
         "remaining_duration":552,
         "start_address":"55 Spear St, San Francisco, CA 94105, USA",
         "end_address":"100 34th Ave, San Francisco, CA 94121, USA",
         "polyline":{
            "type":"LineString",
            "coordinates":[
               [
                  -122.50385,
                  37.76112
               ],
               ...
            ]
         }
      }
   }
```

:::important
Device tracking for your driver's app will be started remotely if you have integrated push notifications with HyperTrack SDK on [iOS](/docs/install-sdk-ios#enable-remote-notifications) and [Android](/docs/install-sdk-android#set-up-silent-push-notifications).

Starting and completing trips would automatically control the start and stop of tracking on the driver's device. This way, your on-demand logistics backend manages device tracking through just one API.

The driver's app would start tracking (unless already tracking) when on-demand logistics backend starts a trip for the device. The device will stop tracking when all active trips for device are completed. HyperTrack uses a combination of silent push notifications and sync method on the SDK to ensure that tracking starts and stops for the device.
:::

### Create driver trip tracking experience in customer app

Once the driver accepts the order, your [customer app](#customer-app) should immediately start showing driver's location with the expected route to the pick up destination and displays ETA in real-time. From the steps above, your on-demand logistics backend created a trip for the driver to the pick up destination. The `trip_id` for this trip is stored by your on-demand logistics backend and is associated with the order.

Customer app uses Views SDK to receive trip status and real-time updates. Your customer app uses callbacks to receive this data and show them in the customer app.

Please review [stream data to native apps guide](/docs/guides/stream-data-to-native-apps) to understand how this is done for iOS and Android apps using Views SDK. Once you integrate Views SDK with the customer app, the customer will be able to:

- See driver moving to the pickup destination in real-timel with an expected route
- Observe route changes as driver diverges from the expected route
- Observe ETA in real-time
- Receive delay notifications in the app

### Complete trip at the pickup destination

Once the driver meets the customer at the pickup destination, the following takes place:

- Driver marks the pickup in the driver app
- On-demand logistics backend sends a request to complete trip with the `trip_id` for the trip to the pick up destination

Your on-demand logistics backend uses Trips API to complete the trip with `trip_id` as follows:

In order to complete the trip, HyperTrack provides you [Trips complete API](/docs/references#references-apis-trips-complete-trip). In the response, you will get markers for activity and outages as to capture history of device movement. Completed trips also include a summary with total duration, distance and steps.

> POST&nbsp&nbsp&nbsp`https://v3.api.hypertrack.com/trips/{trip_id}/complete`

:::important
Driver app tracking will be stopped since you will have integrated push notifications for your app with HyperTrack SDK on [iOS](http://localhost:3000/docs/install-sdk-ios#enable-remote-notifications) and [Android](/docs/install-sdk-android#set-up-silent-push-notifications).
:::

## Track ongoing order to drop off location

Once the driver picks up the customer at the pickup location, your on-demand logistics backend proceeds to work with Trips API to create a trip for the driver to the drop off destination.

### Create a trip with destination at drop off location

Follow steps just as listed in [create a trip with destination at pick up location](#create-a-trip-with-destination-at-pick-up-location) above, with a trip to destination at the drop off location.

### Customer app tracking experience for trip to drop off location

The steps above will generate a new `trip_id`. Using this `trip_id` your customer app will receive real-time trip updates just as described in the above in [create driver trip tracking experience in customer app](#create-driver-trip-tracking-experience-in-customer-app). You replicate the exact steps to support customer's experience of tracking the trip to the drop off location.

### Complete trip at the drop off destination

Once the driver drops off the customer at the drop off destination, the driver marks the order as completed in the app. Once your on-demand logistics backend is notified, it goes ahead to complete active trip with it's `trip_id` via Trips API just as described for the previous steps above in [complete trip at the pickup destination](#complete-trip-at-the-pickup-destination)

## Share tracking updates

As the driver transports the customer to the drop off destination, you can provide real-time location tracking experience to the customer, customer's family, and friends. This can be done with the share URL link as explained below.

### Share URL for trip to drop off location

Trips API gives you an ability for you, as a developer, to create live, real-time, high fidelity, location sharing with your customer via `share_url` link.

Please see an image below for a mobile location sharing viewing experience in the web browser. This link can be shared with family and friend. Once they receive the link, the web browser will continually display and update the location of the driver's device as it moves towards the drop off destination while ETA is updated live.

<p align="center">
<img src="/docs/img/mobile_350px.gif" width="30%" alt="Tracking Experience"/>
</p>

Share URL has the following structure: <code>https://trck.at/{7_digit_tracking_id}</code>.

This makes it a total of 23 characters, and therefore a friendly URL to share via text or other messengers. Share URLs stay accessible permanently and show trip summary after trip completion.

## Generate order summary

Once the oder to the drop off destination is complete, your on-demand logistics backend completes the trip and generates a trip summary that can be shared with both customer and the driver.

A final trip summary view for a trip may look like this:

<p align="center">
<img src="/docs/img/completed_trip_summary.png" width="29%" alt="Tracking Experience"/>
</p>

### Trip summary data

Once the trip is complete, your on-demand logistics backend can obtain detailed trip summary with distance from the pick up destination to drop off destination, including time spent as an input into your app to calculate billing charges for the customer. Please review [](/docs/guides/track-live-route-and-eta-to-destination#getting-trip-summary) to get detailed information on the trip summary data structure.

## Architecture review

In summary, your on-demand apps and backend will work with HyperTrack as follows:

<p align="center">
<img src="/docs/img/manage_on_demand_logistics.png" align="center" width="100%" alt="Location Map" />
</p>


1. Request pickup at location X and dropoff to location Y
2. Get drivers near location X and assign pickup to location X to these drivers
3. A driver accepts order to location X
4. In on-demand logistics backend, create trip with destination X via Trips API
5. Customer tracks driver with ETA to location
6. Driver picks up customer at location X
7. In on-demand logistics backend, complete trip with destination X and create trip with destination Y via Trips API
8. Driver drops off customer at Location Y
9. Complete trip  with  destination Y via Trips API via on-demand logistics backend

## Ridesharing sample app

This works best for product development teams who are starting to build an app for their business and want to kickstart with an open sourced app built with HyperTrack for ridesharing, gig economy, and on-demand delivery use cases.

HyperTrack provides popular open source ridesharing sample apps for <a href="https://github.com/hypertrack/ridesharing-android">Android</a> and <a href="https://github.com/hypertrack/ridesharing-ios">iOS</a>. Clone or fork these sample apps to get started.

<p align="center">
  <a href="https://github.com/hypertrack/ridesharing-android"> <img src="/docs/img/ridesharing-android.png" width="180px"/> </a>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://github.com/hypertrack/ridesharing-ios"> <img src="/docs/img/ridesharing-ios.png" width="180px"/> </a>
</p>

## Questions?

If you would like help with on demand logistics use cases using live location, questions or comments on any of the topics above, please do not hesitate to <a href="mailto:help@hypertrack.com?Subject=Manage on demand logistics" target="_top">contact us</a>.

<Feedback />

## Introduction

We have now entered the second decade of a large variety of on-demand logistics services, such as ridesharing, gig work and on-demand delivery.

These on-demand logistics services include moving, parking, courier, groceries, flowers, dog walks, massages, dry cleaning, vets, medicines, car washes, roadside assistance, cannabis and more.

Through these on-demand platforms, supply and demand are aggregated online for services to be fulfilled offline.

## Creating an on-demand solution

In this tutorial, we consider a ridesharing use case. Learnings from this tutorial can be applied to many of the on-demand logistics services listed above.

A customer requests a pick up at a location chosen by the customer. The pickup order is dispatched to drivers who are available within an area of reach. One of the drivers picks up the customer's request and proceeds to the customer's location for a pick up. Once the pick up takes place, the driver will transport the customer to a destination chosen by the customer.

<p align="center">
<img src="/docs/img/gifs/ride_sharing_demo.gif" width="40%" alt="Ride sharing experience"/>
</p>

### On-demand solution steps

We will go through the following steps:

* [Customer order](#customer-order): Customer books an order from desired pickup and drop off location
* [Driver registration](#driver-registration): Driver registers with on-demand logistics backend
* [Locate nearby drivers](#locate-nearby-drivers): Customer's request is matched with nearest drivers available
* [Assign and accept order](#assign-and-accept-order): Customer's request assigned to avaiable drivers and is accepted
* [Track driver to customer's pickup location](#track-driver-to-customer-pickup-location): Create driver tracking experience for the customer
* [Track the ongoing order to drop off location](#track-ongoing-order-to-drop-off-location): Track live location of customer going to the drop off location
* [Share tracking updates](#share-tracking-updates): Enable the customer share whereabouts with friends and family
* [Generate order summary](#generate-order-summary): Generate and share order summary for billing and record-keeping purposes

## On-demand solution components

Before we proceed to go through the steps required to create an on-demand solution, we need to build the following components:

* Customer app
* Driver app
* On-demand logistics backend

### Customer app

Customer app is a mobile app which helps achieve the following:

- Displaying nearby drivers as an option offered to the customer.
- Order request that can be sent to the on-demand logistics backend
- Tracking driver to the customer's pickup location. To achieve this, the customer's app uses [Views SDK](/docs/guides/stream-data-to-native-apps) to provide real-time location updates to the customer
- Track customer's trip to the customer's destination. The customer's app uses [Views SDK](/docs/guides/stream-data-to-native-apps) to provide real-time location updates to the customer
- Display trip summary to the customer after the trip completion. This is done with [Views SDK](/docs/guides/stream-data-to-native-apps)

:::note
Customer app does **not** track location of the customer. No location permissions are necessary to be requested from the customer to support the tracking experience.
:::

### Driver app

Driver app is another mobile app which helps achieve the following:

- Driver registration and authentication with your on-demand logistics backend
- Displaying assigned order request to the driver
- Order request acceptance
- Generating location data for the customer to track the driver to both pickup destination as well as to drop off destination
- Pickup and drop off order completion and sign off

:::note
Driver app **tracks** the driver. Location and motion permissions are necessary to be requested from the driver to track an order.
:::

### On-demand logistics backend

On-demand logistics backend is built to achieve the following:

- Customer and driver registration and management
- Customer order requests
- Find nearby drivers and assign customer order requests with [Nearby API](#making-a-request-to-get-nearby-drivers)
- Receive driver acceptance for orders
- Manage trips to customer's pickup and drop off locations with [Trips API](/docs/references#references-apis-trips)

## Customer order

On-demand customer downloads and installs the [customer app](#customer-app) and signs in. Customer can use the app to book an order.

### Customer registration

Your customer app and on-demand logistics backend implement customer registration by capturing customer's identity and verifying customer's credentials. You store customer's information in your on-demand logistics backend. The customer's identity and credentials are used to authenticate customer's order request and present to assigned drivers.

### Order execution

The customer picks a location and orders a pickup to go to a destination. The on-demand logistics backend receives the order and stores it in its database for the next step. This step will involve finding available drivers near pickup location as explained below.

## Driver registration

The driver downloads the [driver app](#driver-app), registers and authenticates to your on-demand logistics backend. In the process of registration, driver app captures driver's `device_id` from HyperTrack SDK which is sent to on-demand logistics backend along with the driver's identity and credentials.

To add location tracking to your on-demand solution, you must add HyperTrack SDK to your driver app. Please use one of the following options.

### Enable location tracking in driver app

Follow these instructions to install the SDK.

- [Android SDK](/docs/install-sdk-android)
- [iOS SDK](/docs/install-sdk-ios)
- [Flutter SDK](/docs/install-sdk-flutter)
- [React Native SDK](/docs/install-sdk-react-native)

### Identify drivers

In order to provide a great on-demand experience for customers, add driver identity as the name for your driver's device. The driver's name will show in your customer's app.

Review instructions on how to set [device name and metadata](/docs/guides/setup-and-manage-devices#setting-device-name-and-metadata) and make a decision on what works best for your on-demand app.

For example, the device name can be a driver's name or some other identifier you use in your system with example below:

```shell script
{
  "name": "Kanav",
  "metadata": {
    "model": "i3",
    "make": "BMW",
    "color": "blue"
  }
}
```

## Locate nearby drivers

Live location is an important input to the driver dispatch algorithm to request a pickup and dropoff. 

For further details, documentation and code examples, please review [Nearby API guide](/docs/guides/dispatch-work-to-nearby-devices).

Nearby API locates app users on demand, figures out which ones are nearest to the location of interest, and returns them as an ordered list with nearest first. 

### Make a request to get nearby drivers

First, use this POST [Nearby API](/docs/references#references-apis-nearby-api) request to find available drivers near pickup location.

>POST&nbsp&nbsp&nbsp`https://v3.api.hypertrack.com/devices/nearby`

Nearby API HTTP POST uses a payload structure like this below.

```shell script
{
	"location": {
		"coordinates": [
          -122.402007, 37.792524
        ],
		"type" : "Point"
    },
    "radius" : 1000,
    "metadata": {
        "gig_type": "ridesharing",
        "order": "rider_A_pickup_at_location_X"
    }
}
```

In the above payload example `location` and `radius` of represent a circular area of 2km in diameter centered at a gig location `-122.402007, 37.792524` within which devices are considered nearby.

The `metadata` parameter is optional to apply filtering (e.g only looking for devices within a city/region)
In place of `metadata`, filtered list of device_ids can also be be provided directly via `devices` parameter as shown below.

```shell script
{
	"location": {
		"coordinates": [
          -122.402007, 37.792524
        ],
		"type" : "Point"
    },
    "radius" : 1000,
    "devices":[
      "00112233-531B-4FC5-AAC5-3DB7886FE3D2",
      "00112233-E0A7-4217-8175-888CA30C5225"
      ]
}
```
    
Upon making request with above payload, you will get an HTTP 202 response with the below payload like this below.

### Return response data

Nearby API POST request returns a response that contains `request_url` string. This is the Nearby API GET call you need to invoke to obtain nearby devices.

```shell script
{
    "request_url": 'https://v3.api.hypertrack.com/devices/nearby?request_id=09f63b10-9bbc-4b24-af1a-d8ac84644fcc&limit=100'}
}
```
### Fetch request results

In order to fetch nearby devices corresponding to the above request, make a GET request to the above `request_url` sent in POST API response.

>GET&nbsp&nbsp&nbsp`https://v3.api.hypertrack.com/devices/nearby?request_id={request_id}&limit={limit}&{pagination_token}`

Parameters `limit` and `pagination_token` are optional to paginate the response.

Upon making the above request, you will get an HTTP 200 response with this below payload. Make a note of `status` field which indicates whether the request is in `pending` or `completed` status.

```shell script
{
   "data":[
      {
         "device_info":{
            "device-model":"IPhone X",
            ...
         },
         "metadata":{
            "key_1":"value_1"
         },
         "location":{
            ...
            "geometry":{
               "coordinates":[
                  35.10654,
                  47.847252,
                  610
               ],
               "type":"Point"
            },
            ... 
         },
         ...
         "nearby_devices_request_id":"09f63b10-9bbc-4b24-af1a-d8ac84644fcc",
         "device_id":"00112233-FFA6-404C-A30F-27B38836A887",
         ... 
      }
   ],
   "status":"pending"
}

```

Here `data` is the list of devices which are ranked based on their distance from gig location (nearest first). You may poll this GET `request_url` as additional devices are found and identified nearby.

### Receiving request completion notification

In addition to GET /devices/nearby API, you will also get notified about the completion of a request via webhook notification with below payload example structure.

```shell script
 {
    "created_at": "2020-04-29T02:25:59.906839Z",
    "type": "nearby_devices_request",
    "data": {
        "value": "completed",
        "request_id": "09f63b10-9bbc-4b24-af1a-d8ac84644fcc",
        "location": {
                "coordinates": [
                  -122.402007, 37.792524
                ],
                "type" : "Point"
            },
        "metadata": {
            "team": "san_francisco",
            "gig_type": "delivery"
        }
        "radius": 1000
    },
    'version': '2.0.0'
 }

```

Once you receive the notification, you will be able to make a final GET `request_url` call to obtain a list of devices that HyperTrack determines to be nearby the location of interest. These are drivers that can be presented with the customer's request.

:::note
See [Nearby API guide](/docs/guides/dispatch-work-to-nearby-devices) for detailed documentation and code examples.
:::

## Assign and accept order

Once nearby available drivers located, customer's request is assigned to available drivers by your on-demand logistics backend and presented in their driver app. One of the drivers can accept the order and drive to the pickup location.

### Assign order request to available drivers

On-demand logistics backend receives results of [Nearby API](#locate-nearby-drivers) and assigns order request to the nearest available drivers. Your [driver app](#driver-app) presents the pickup order in the screen to each of these available drivers, along with the identity of the customer and pickup location.

<p align="center">
<img src="/docs/img/driver_order_presented.png" width="30%" alt="Tracking Experience"/>
</p>

### Driver acceptance

As illustrated in the image above, driver app gives an opportunity for the driver to accept an assigned order. Once the driver accepts the order, on-demand logistics backend proceeds to create a trip for the driver to the pickup location as explained below.

## Track driver to customer pickup location

Once the driver accepted the pickup order, your on-demand logistics backend proceeds to work with Trips API to create a trip for the driver to the destination at pickup location and provide a real-time tracking experience to the customer.

### Create a trip with destination at pick up location

To create driver tracking experience for the customer, create a trip with ETA to the pickup destination. Once the pickup order is accepted by the driver, inside your on-demand logistics backend, Use [Trips API](/docs/guides/track-live-route-and-eta-to-destination#create-a-trip-with-destination) to create a trip for driver.

See the code example below that creates a trip with ETA for driver's `device_id`, with pickup `destination`:

<Tabs defaultValue="js" values={[
{label: "JavaScript", value:"js"},
{label: "Python", value:"py"},
{label: "Java", value:"java"},
{label: "PHP", value:"php"},
{label: "Ruby", value:"ruby"}
]
}>

<TabItem value="js">

```js

// Instantiate Node.js helper library instance
const hypertrack = require('hypertrack')(accountId, secretKey);

let tripData = {
  "device_id": "00112233-4455-6677-8899-AABBCCDDEEFF",
  "destination": {
    "geometry": {
      "type": "Point",
      "coordinates": [35.107479, 47.856564]
    }
  }
};

hypertrack.trips.create(tripData).then(trip => {
  // Trip created
}).catch(error => {
  // Error handling
})

```

</TabItem>
<TabItem value="py">

```py
// Use HyperTrack Python library

from hypertrack.rest import Client
from hypertrack.exceptions import HyperTrackException

hypertrack = Client({AccountId}, {SecretKey})

trip_data = {
  "device_id": "00112233-4455-6677-8899-AABBCCDDEEFF",
  "destination": {
    "geometry": {
      "type": "Point",
      "coordinates": [35.10747945667027, 47.8565694654932]
    }
  }
}

trip = hypertrack.trips.create(trip_data)
print(trip)

```

</TabItem>
<TabItem value="java">

```java
OkHttpClient client = new OkHttpClient();

MediaType mediaType = MediaType.parse("application/json");
RequestBody body = RequestBody.create(mediaType,"{\n" +
        "  \"device_id\": \"00112233-4455-6677-8899-AABBCCDDEEFF\",\n" +
        "  \"destination\": {\n" +
        "    \"geometry\": {\n" +
        "      \"type\": \"Point\",\n" +
        "      \"coordinates\": [-122.3980960195712, 37.7930386903944]\n" +
        "    }\n" +
        "  }\n" +
        "}");

String authString = "Basic " +
  Base64.getEncoder().encodeToString(
    String.format("%s:%s", "account_id_value","secret_key_value")
      .getBytes()
  );

Request request = new Request.Builder()
  .url("https://v3.api.hypertrack.com/trips/")
  .post(body)
  .addHeader("Authorization", authString)
  .build();

Response response = client.newCall(request).execute();

System.out.println(response.body().string());
```

</TabItem>
<TabItem value="php">

```php
<?php

$request = new HttpRequest();
$request->setUrl('https://v3.api.hypertrack.com/trips/');
$request->setMethod(HTTP_METH_POST);

$basicAuth = "Basic " . base64_encode('{AccountId}' . ':' . '{SecretKey}');

$request->setHeaders(array(
  'Authorization' => $basicAuth
));

$request->setBody('{
    "device_id": "00112233-4455-6677-8899-AABBCCDDEEFF",
    "destination": {
        "geometry": {
            "type": "Point",
            "coordinates": [
                -122.3980960195712,
                37.7930386903944
            ]
        }
    }
}');

try {
  $response = $request->send();

  echo $response->getBody();
} catch (HttpException $ex) {
  echo $ex;
}

?>
```

</TabItem>
<TabItem value="ruby">

```ruby
require 'uri'
require 'net/http'
require 'base64'
require 'json'

url = URI("https://v3.api.hypertrack.com/trips/")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

request = Net::HTTP::Post.new(url)
request["Authorization"] = 'Basic ' + Base64.strict_encode64( '{AccountId}' + ':' + '{SecretKey}' ).chomp
request.body = {
    "device_id": "00112233-4455-6677-8899-AABBCCDDEEFF",
    "destination": {
        "geometry": {
            "type": "Point",
            "coordinates": [
                -122.3980960195712,
                37.7930386903944
            ]
        }
    }
}.to_json

response = http.request(request)
puts response.read_body
```

</TabItem>
</Tabs>

### Understanding Trips API create trip response

Once the trip is created, the Trips API responds with an active trip object that returns the original payload with additional properties.

You will get an example payload response like the one below. In the response you get estimate (route/ETA) to destination, shareable URL for customers, embed URL for ops dashboards for active ( as noted in `status` field in the response ) trip.

The `destination` object in the response will now contain `address` field which is an address that HyperTrack determines ( reverse geocodes ) based on `destination` coordinates you submitted in the trips creation request above. You can use this `address` to show the destination to the user after creating the trip.


```json title="HTTP 201 - New trip with destination"
{
   "trip_id":"2a819f6a-5bee-4192-9077-24fc61503ae9",
   "device_id":"00112233-4455-6677-8899-AABBCCDDEEFF",
   "started_at":"2020-04-20T00:57:33.484361Z",
   "completed_at":null,
   "status":"active",
   "views":{
      "embed_url":"https://embed.hypertrack.com/trips/2a819f6a-5bee-4192-9077-24fc61503ae9?publishable_key=<your_publishable_key>",
      "share_url":"https://trck.at/abcdef"
   },
   "device_info":{
      "os_version":"13.3.1",
      "sdk_version":"4.0.2-rc.5"
   },
   "destination":{
      "geometry":{
         "type":"Point",
         "coordinates":[
            -122.500005,
            37.785334
         ]
      },
      "radius":30,
      "scheduled_at":null,
      "address":"100 34th Ave, San Francisco, CA 94121, USA"
   },
   "estimate":{
      "arrive_at":"2020-04-20T01:06:45.914154Z",
      "route":{
         "distance":4143,
         "duration":552,
         "remaining_duration":552,
         "start_address":"55 Spear St, San Francisco, CA 94105, USA",
         "end_address":"100 34th Ave, San Francisco, CA 94121, USA",
         "polyline":{
            "type":"LineString",
            "coordinates":[
               [
                  -122.50385,
                  37.76112
               ],
               ...
            ]
         }
      }
   },
   "eta_relevance_data":{
      "status":true
   }
}
```

### Estimate object in Trip API response

The Trips API responds with an active trip object that returns the original payload with additional properties. HyperTrack provides estimates for every trip with a destination.

Since in the API request we specified a destination, the Trips API response will return the `estimate` object with fields are explained here as follows:

- Field `arrive_at` shows estimated time of arrival (ETA) as UTC timestamp
- Object `route` contains the following data:
  - Field `distance` shares estimated route distance (in meters)
  - Fields `duration` and `remaining_duration` share actual and remaining durations (in seconds)
  - Fields `start_address` and `end_address` display reverse geocoded place names and addresses for trip start, complete and intermediate stops (based on activity)
  - Field `polyline` contains an array of coordinates for the estimated route from the live location to the destination as polyline in GeoJSON [`LineString`](http://wiki.geojson.org/GeoJSON_draft_version_6#LineString) format. It is an array of Point coordinates with each element linked to the next, thus creating a pathway to the destination.

```json title="HTTP 201 - New trip with destination"
   "estimate":{
      "arrive_at":"2020-04-20T01:06:45.914154Z",
      "route":{
         "distance":4143,
         "duration":552,
         "remaining_duration":552,
         "start_address":"55 Spear St, San Francisco, CA 94105, USA",
         "end_address":"100 34th Ave, San Francisco, CA 94121, USA",
         "polyline":{
            "type":"LineString",
            "coordinates":[
               [
                  -122.50385,
                  37.76112
               ],
               ...
            ]
         }
      }
   }
```

:::important
Device tracking for your driver's app will be started remotely if you have integrated push notifications with HyperTrack SDK on [iOS](/docs/install-sdk-ios#enable-remote-notifications) and [Android](/docs/install-sdk-android#set-up-silent-push-notifications).

Starting and completing trips would automatically control the start and stop of tracking on the driver's device. This way, your on-demand logistics backend manages device tracking through just one API.

The driver's app would start tracking (unless already tracking) when on-demand logistics backend starts a trip for the device. The device will stop tracking when all active trips for device are completed. HyperTrack uses a combination of silent push notifications and sync method on the SDK to ensure that tracking starts and stops for the device.
:::

### Create driver trip tracking experience in customer app

Once the driver accepts the order, your [customer app](#customer-app) should immediately start showing driver's location with the expected route to the pick up destination and displays ETA in real-time. From the steps above, your on-demand logistics backend created a trip for the driver to the pick up destination. The `trip_id` for this trip is stored by your on-demand logistics backend and is associated with the order.

Customer app uses Views SDK to receive trip status and real-time updates. Your customer app uses callbacks to receive this data and show them in the customer app.

Please review [stream data to native apps guide](/docs/guides/stream-data-to-native-apps) to understand how this is done for iOS and Android apps using Views SDK. Once you integrate Views SDK with the customer app, the customer will be able to:

- See driver moving to the pickup destination in real-timel with an expected route
- Observe route changes as driver diverges from the expected route
- Observe ETA in real-time
- Receive delay notifications in the app

### Complete trip at the pickup destination

Once the driver meets the customer at the pickup destination, the following takes place:

- Driver marks the pickup in the driver app
- On-demand logistics backend sends a request to complete trip with the `trip_id` for the trip to the pick up destination

Your on-demand logistics backend uses Trips API to complete the trip with `trip_id` as follows:

In order to complete the trip, HyperTrack provides you [Trips complete API](/docs/references#references-apis-trips-complete-trip). In the response, you will get markers for activity and outages as to capture history of device movement. Completed trips also include a summary with total duration, distance and steps.

> POST&nbsp&nbsp&nbsp`https://v3.api.hypertrack.com/trips/{trip_id}/complete`

:::important
Driver app tracking will be stopped since you will have integrated push notifications for your app with HyperTrack SDK on [iOS](http://localhost:3000/docs/install-sdk-ios#enable-remote-notifications) and [Android](/docs/install-sdk-android#set-up-silent-push-notifications).
:::

## Track ongoing order to drop off location

Once the driver picks up the customer at the pickup location, your on-demand logistics backend proceeds to work with Trips API to create a trip for the driver to the drop off destination.

### Create a trip with destination at drop off location

Follow steps just as listed in [create a trip with destination at pick up location](#create-a-trip-with-destination-at-pick-up-location) above, with a trip to destination at the drop off location.

### Customer app tracking experience for trip to drop off location

The steps above will generate a new `trip_id`. Using this `trip_id` your customer app will receive real-time trip updates just as described in the above in [create driver trip tracking experience in customer app](#create-driver-trip-tracking-experience-in-customer-app). You replicate the exact steps to support customer's experience of tracking the trip to the drop off location.

### Complete trip at the drop off destination

Once the driver drops off the customer at the drop off destination, the driver marks the order as completed in the app. Once your on-demand logistics backend is notified, it goes ahead to complete active trip with it's `trip_id` via Trips API just as described for the previous steps above in [complete trip at the pickup destination](#complete-trip-at-the-pickup-destination)

## Share tracking updates

As the driver transports the customer to the drop off destination, you can provide real-time location tracking experience to the customer, customer's family, and friends. This can be done with the share URL link as explained below.

### Share URL for trip to drop off location

Trips API gives you an ability for you, as a developer, to create live, real-time, high fidelity, location sharing with your customer via `share_url` link.

Please see an image below for a mobile location sharing viewing experience in the web browser. This link can be shared with family and friend. Once they receive the link, the web browser will continually display and update the location of the driver's device as it moves towards the drop off destination while ETA is updated live.

<p align="center">
<img src="/docs/img/mobile_350px.gif" width="30%" alt="Tracking Experience"/>
</p>

Share URL has the following structure: <code>https://trck.at/{7_digit_tracking_id}</code>.

This makes it a total of 23 characters, and therefore a friendly URL to share via text or other messengers. Share URLs stay accessible permanently and show trip summary after trip completion.

## Generate order summary

Once the oder to the drop off destination is complete, your on-demand logistics backend completes the trip and generates a trip summary that can be shared with both customer and the driver.

A final trip summary view for a trip may look like this:

<p align="center">
<img src="/docs/img/completed_trip_summary.png" width="29%" alt="Tracking Experience"/>
</p>

### Trip summary data

Once the trip is complete, your on-demand logistics backend can obtain detailed trip summary with distance from the pick up destination to drop off destination, including time spent as an input into your app to calculate billing charges for the customer. Please review [](/docs/guides/track-live-route-and-eta-to-destination#getting-trip-summary) to get detailed information on the trip summary data structure.

## Architecture review

In summary, your on-demand apps and backend will work with HyperTrack as follows:

<p align="center">
<img src="/docs/img/manage_on_demand_logistics.png" align="center" width="100%" alt="Location Map" />
</p>


1. Request pickup at location X and dropoff to location Y
2. Get drivers near location X and assign pickup to location X to these drivers
3. A driver accepts order to location X
4. In on-demand logistics backend, create trip with destination X via Trips API
5. Customer tracks driver with ETA to location
6. Driver picks up customer at location X
7. In on-demand logistics backend, complete trip with destination X and create trip with destination Y via Trips API
8. Driver drops off customer at Location Y
9. Complete trip  with  destination Y via Trips API via on-demand logistics backend





# TODO TODO TODO


Uber’s business model has given rise to a large number of Uber-for-X services. Among other things, X equals moving, parking, courier, groceries, flowers, alcohol, dog walks, massages, dry cleaning, vets, medicines, car washes, roadside assistance and marijuana. Through these on-demand platforms, supply and demand are aggregated online for services to be fulfilled offline.

This open source repo/s uses HyperTrack SDK for developing real world Uber-like consumer & driver apps.

 - **Ridesharing Rider app** can be used by customer to :
      - Allow customer to select pickup and dropoff location
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

- **Ridesharing Driver app** can be used by driver to :
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

## Architecture

- The Driver App uses HyperTrack SDK ([iOS](https://github.com/hypertrack/quickstart-ios)/[Android](https://github.com/hypertrack/quickstart-android)) to send its location, name, and metadata to HyperTrack's servers
- Driver and Rider Apps use HyperTrack Views SDK ([iOS](https://github.com/hypertrack/views-ios)/[Android](https://github.com/hypertrack/views-android)) to show the driver's current location and trip's route
- Driver and Rider Apps are subscribed to [Firebase Cloud Firestore](https://firebase.google.com/docs/firestore) to sync users and orders between them
- Firebase Cloud Functions react to the order status field in Cloud Firestore, create and complete trips using [HyperTrack Trips APIs](https://www.hypertrack.com/docs/guides/track-trips-with-destination), listen to [HyperTrack Webhooks](https://www.hypertrack.com/docs/guides/track-trips-with-destination#get-trip-updates-on-webhooks) and update the order status and trip fields with new results


![Architecture](Images/ArchitectureUpdated.png)

<details>
    <summary>Step by step process of communication:</summary>

1. **Request pickup at location X for a ride to location Y**
   - Prior to requesting a pickup, Rider App has already signed up with Ride Sharing App Backend. Ride Sharing App Backend created a new document with the rider's data in its users collection
   - The rider chooses pickup and dropoff places. Rider App sends a request to Ride Sharing App Backend, which creates a new order in its orders collection in Cloud Firestore
2. **Assign ride to location X to driver**
   - Prior to the assignment, Driver App already signed up with Ride Sharing App Backend:
     - Ride Sharing App Backend created a new document with the driver's data in its users collection in Cloud Firestore
     - Driver App added name and metadata through HyperTrack SDK
     - HyperTrack SDK started tracking the driver's location  
     - From this point, the driver can be seen in HyperTrack Dashboard
3. **Driver accepts ride to location X**
   - Driver App is checking with Ride Sharing App Backend periodically, looking for orders with the `NEW` status
   - Once the new order(s) show up, the driver can accept a chosen order. Ride Sharing Backend changes the order status to `ACCEPTED` and sets the driver's data in the order 
4. **Create trip with destination X via Trips API**
   - Once the order status is changed, Ride Sharing Backend triggers `updateOrderStatus` Firebase Cloud Function. The function creates a trip from the driver's current position to the rider's pickup point using [HyperTrack API](https://www.hypertrack.com/docs/guides/track-trips-with-destination). Once the troop is created, the order status is changed to `PICKING_UP`.
5. **Rider tracks driver with ETA to location**
   - Driver and Rider Apps are subscribed to their order. When they see that the status is `PICKING_UP`, they use HyperTrackViews SDK to display the trip live from the order on a map
6. **Driver picks up rider at location X**
   - When the driver crosses destination geofence of the rider's pickup point, a webhook from HyperTrack to Ride Sharing App Backend's Firebase Cloud Function is triggered. This function updates the order to `REACHED_PICKUP` state
7. **Complete trip with destination X and create trip with destination Y via Trips API**
   - Upon receiving `REACHED_PICKUP` order state, Driver App shows a "Start Trip" button. When the driver presses it, Driver App changes the order status to `STARTED_RIDE` state
   - Upon receiving the `STARTED_RIDE` state, Ride Sharing App Backend's Firebase Cloud Function calls [HyperTrack APIs](https://www.hypertrack.com/docs/guides/track-trips-with-destination) to complete the previous trip and creates a new trip to the rider's destination. After the trip is created, the function updates the order status to `DROPPING_OFF`
   - When Driver and Rider Apps see `PICKING_UP` status, they both use HyperTrack Views SDK to display the new trip on a map
8. **Driver drops off rider at Location Y**
   - When the driver crosses the destination geofence of the rider's dropoff point, a webhook from HyperTrack to Ride Sharing App Backend's Firebase Cloud Function triggers again. This function updates the order to `REACHED_DROPOFF` state
   - Upon receiving `REACHED_DROPOFF` order state, the Driver app shows a "End Trip" button. When the driver presses it, Driver app changes the order status to `COMPLETED` state
9. **Complete trip  with  destination Y via Trips API**
   - Ride Sharing App Backend's Firebase Cloud Function proceeds to call [HyperTrack APIs](https://www.hypertrack.com/docs/guides/track-trips-with-destination) complete the dropoff trip 
   - When this trip is completed, Rider and Driver Apps show trip summary using HyperTrack Views SDK
</details>

## How Ridesharing sample apps use HyperTrack API

Ridesharing apps use [HyperTrack Trips API](https://www.hypertrack.com/docs/guides/track-trips-with-destination) to [create](https://www.hypertrack.com/docs/references/#references-apis-trips-start-trip-with-destination) and [complete](https://www.hypertrack.com/docs/references/#references-apis-trips-complete-trip) trips by using Firebase Cloud Functions. Firebase allows ridesharing sample appilcations integrate with HyperTrack Trips API via backend server integration.

For each rider's request that is accepted by the driver, a trip is [created](https://www.hypertrack.com/docs/references/#references-apis-trips-start-trip-with-destination) for the driver to pick up the rider at the rider's location. Once the pick up is completed, the trip is [completed](https://www.hypertrack.com/docs/references/#references-apis-trips-complete-trip) and then the new trip is [created](https://www.hypertrack.com/docs/references/#references-apis-trips-start-trip-with-destination) for the driver to get the rider to rider's destination. Once the rider reaches the destination and is dropped off, the trip is [completed](https://www.hypertrack.com/docs/references/#references-apis-trips-complete-trip).

## How Ridesharing sample apps use HyperTrack SDK

Ridesharing Driver app uses HyperTrack SDK to track driver's position in 3 cases:
- When app is active to display all drivers locations on riders maps
- When driver is picking up rider
- When driver is dropping off rider

You can find the SDK documentation [here](https://github.com/hypertrack/quickstart-ios).

### Silent push notifications

Driver app integrates HyperTrack SDK with silent push notifictions to:
- Start tracking location immediately when Firebase creates a trip for accepted order
- Stop tracking location when app is backgrounded and there are no trips lift

HyperTrack SDK has four methods to integrate silent push notifications:
- `registerForRemoteNotifications()`, registers the app in OS to receive notifications
- `didRegisterForRemoteNotificationsWithDeviceToken(_:)` to transfer device token to HyperTrack SDK
- `didFailToRegisterForRemoteNotificationsWithError(_:)` to signal failure to register for remote notifications
- `didReceiveRemoteNotification(_:fetchCompletionHandler:)` transfers silent push notification to HyperTrack SDK

Here is how they are integrated in Driver app:
```swift
 func application(
    _: UIApplication,
    didFinishLaunchingWithOptions
    _: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    /// Register for remote notifications to allow bi-directional communication model with the
    /// server. This enables the SDK to run on a variable frequency model, which balances the
    /// fine trade-off between low latency tracking and battery efficiency, and improves robustness.
    /// This includes the methods below in the Remote Notifications section
    HyperTrack.registerForRemoteNotifications()
    /// Configure Firebase
    FirebaseApp.configure()
    return true
  }

  func application(
    _: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    HyperTrack.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
  }

  func application(
    _: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    HyperTrack.didFailToRegisterForRemoteNotificationsWithError(error)
  }

  func application(
    _: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler:
    @escaping (UIBackgroundFetchResult) -> Void
  ) {
    HyperTrack.didReceiveRemoteNotification(
      userInfo,
      fetchCompletionHandler: completionHandler
    )
  }
```

### SDK Initialization

HyperTrack SDK initializes successfully when nothing prevents it from tracking. This is modeled by `Result` type. Here, in Driver app, when `Result` is `.success` we present one UI and when it's `.failure` another. This ensures that UI that get initialized SDK won't get null, and can use the SDK freely, and UIs designed for error handling won't get SDK at all, and will only display errors.

```swift
switch HyperTrack.makeSDK(
  publishableKey: HyperTrack.PublishableKey(getPublishableKeyfromPlist())!
) {
  case let .success(hypertrack):
    let store = Store(
      initialValue: AppState(),
      reducer: appReducer
    )
    let dataflow = DriverDataFlow(store: store, hypertrack: hypertrack)
    return AnyView(ContentView(
      store: store,
      dataflow: dataflow,
      hypertrack: hypertrack
    ))
  case let .failure(error):
    switch error {
      case let .developmentError(devError):
        fatalError("\(devError)")
      case let .productionError(prodError):
        return AnyView(ErrorView(store: Store(
          initialValue: AppState(),
          reducer: appReducer
        ), error: HError(error: prodError)))
    }
}
```

### DeviceID

DeviceID is used to identify a device on HyperTrack. Driver app uses this ID when creating a user in Firebase.

```swift
private func makeNewUser() {
  let user = User(
    id: nil,
    role: .driver,
    name: name,
    phone_number: phone,
    device_id: hypertrack.deviceID,
    car: User.Car(model: carModel, license_plate: carPlate)
  )
  setNewFirestoreUser(db, user) { result in
    switch result {
      case let .success(user):
        self.makeHTUser(user)
        self.store.value.user = user
        self.store.update(.permissions)
      case let .failure(error):
        print("An error occurred: \(error)")
    }
  }
}
```

Later in Views SDK snippets, both Driver and Rider app are using this ID to display driver on a map.

### Device name and metadata

Device name and metadata are displayed in HyperTrack's [dashboard](https://dashboard.hypertrack.com). To make it easy for operators to find drivers by their name or filter them by metadata, Driver app sets those fields using User model from Firebase:

```swift
private func makeHTUser(_ user: User) {

  let id = user.id ?? ""
  let name = user.id ?? ""
  let phoneNumber = user.phone_number ?? ""
  let carModel = user.car?.model ?? ""
  let carLicensePlate = user.car?.license_plate ?? ""
  let car = ["model": carModel, "license_plate": carLicensePlate]

  hypertrack.setDeviceName(user.name)
  if let metadata = HyperTrack.Metadata(dictionary: [
    "user_id": id,
    "name": name,
    "phone_number": phoneNumber,
    "car": car
  ]) {
    hypertrack.setDeviceMetadata(metadata)
  }
}
```

### Start tracking and sync device settings

Driver app tracks the driver in an interesting way. We want to always track driver when the app is running in foreground. This allows us to show cars of available drivers in Rider app's map. At the same time we want to track drivers in background only when they have an active order. In this snippet we subscribe to OS notifications and call `start()` tracking when app is brought to foreground. But when the app is going into background we consult with `syncDeviceSettings()` to stop tracking if driver doesn't have active trips.

```swift
.onReceive(appStateReceiver.$notification) { notification in
  switch(notification.name, self.store.value.user) {
    case (UIApplication.didBecomeActiveNotification, let user):
      self.hypertrack.start()
    case (UIApplication.didEnterBackgroundNotification, _):
      self.hypertrack.syncDeviceSettings()
    default: break
  }
}
```

## How Ridesharing sample apps use Views SDK

Both Rider and Driver apps use [HyperTrackViews SDK](https://github.com/hypertrack/views-ios) to display realtime location and trip updates on a map.

### Subscribing to location updates

Both Driver and Rider apps subscribe to driver's location updates using `subscribeToMovementStatusUpdates(for:completionHandler:)` method:

```swift
func createUserMovementStatusSubscription() {
  ht_cancelable =
    hyperTrackViews.subscribeToMovementStatusUpdates(
      for: self.hypertrack.deviceID,
      completionHandler: { [weak self] result in
        guard let self = self else { return }
        switch result {
          case let .success(movementStatus):
            self.movementStatusWillChange.send(movementStatus)
            self.getTripSummary()
          case let .failure(error):
            dump(error)
            self.createUserMovementStatusSubscription()
        }
      }
    )
}
```

### Placing device or trip on a map

MapKit part of the library can put any `CLLocation` as devices location.

Driver's location is taken from MovementStatus:

```swift
private func configureForNewState(_ mapView: MKMapView) {
  removeAllAnnotationExceptDeviceAnnotation(mapView: mapView)
  mapView.addAnnotations(dataflow.orderList.map { OrderAnnotation(order: $0) } )
  if let movementStatus = self.movementStatus {
    put(.location(movementStatus.location), onMapView: mapView)
  }
}
```

Rider's location is taken from the map itself:

```swift
private func configureForLookingState(_ mapView: MKMapView) {
  guard let location = self.location else { return }
  put(.location(location), onMapView: mapView)
}
```

When driver is picking up or dropping off rider, the estimated route is displayed. This route comes from a trip, and `.locationWithTrip` enum is used to display both driver's current position and his route to destination:

```swift
private func configureForDrivingState(_ mapView: MKMapView) {
  if let device = self.dataflow.userMovementStatus, let trip = mStatus.trips.first(
    where: { $0.id == self.dataflow.store.value.order?.trip_id }
  ) {
    put(.locationWithTrip(device.location, trip), onMapView: mapView)
  } else {
    configureForLookingState(mapView)
  }
}
```

### Making the device or trip center on a map

In apps that show tracking data, usually user needs to see all the data on the screen, be it current location, trip polylines or destination markers. This view needs to re-zoom with animation every time the data is changing. This is done in the Uber app.

We also don't want to auto-zoom if user touched the map and zoomed in to his location of choise. In this snippet a private function decides, based on user's input, if auto-zoom is needed and uses our Views function (`zoom(withMapInsets:interfaceInsets:onMapView:)`) that understands what is shown on the screen (be it current location, trip or summary) and auto-zooms on it.

This function can take different values for insets based on distance in meters (here we are making an inset for 100 meters in all directions, so elements won't touch the screen. But also there are cases where UI elements are shown on top of our map, and in those cases we don't want to accidentally miss relevent data under those elemets. For those cases the zoom function has interfaceInsets parameter.

In this case we have a card at the bottom 250 points in height, and a statusbar element at the top for 10 points.

```swift
private func isZoomNeeded(_ mapView: MKMapView) {
  if self.isAutoZoomEnabled {
    zoom(
      withMapInsets: .all(100),
      interfaceInsets: .custom(
        top: 10,
        leading: 10,
        bottom: 250,
        trailing: 10),
      onMapView: mapView)
  }
}
```

## How to Begin

### 1. Get your keys
 - [Signup](https://dashboard.hypertrack.com/signup) to get your [HyperTrack Publishable Key](https://dashboard.hypertrack.com/setup)

### 2. Set up rider & driver app
```bash
# Clone this repository
$ git clone https://github.com/hypertrack/ridesharing-ios.git

# cd into the project directory
$ cd ridesharing-ios

# Install dependencies (can take a while)
$ pod install
```

- Open Ridesharing.xcworkspace
- Add the publishable key to Utility > [`Interface.swift`](https://github.com/hypertrack/ridesharing-ios/blob/e46306c06e3f8b0d9a7372ef15663dc509451b1e/Utility/Interface.swift#L10) > `let publishableKey` constant
```swift
public let publishableKey: String = "YOUR_PUBLISHABLE_KEY_HERE"
```

### 3. Set up Firebase
 - Create a Firebase project. For detail steps refer to _Step 1_: https://firebase.google.com/docs/ios/setup#create-firebase-project
 - Register Driver app with `com.hypertrack.ridesharing.driver.ios.github` bundle ID and Rider app with `com.hypertrack.ridesharing.rider.ios.github` bundle ID. More details in _Step 2_: https://firebase.google.com/docs/ios/setup#register-app
 - Move Driver app's `GoogleService-Info.plist` to the Driver app target and Rider's to Riders. Described in _Step 3_: https://firebase.google.com/docs/ios/setup#add-config-file No need to follow Step 4 and 5, they are already implemented in the app.
 - Create Cloud Firestore database in test mode by following the "Create a Cloud Firestore database" section from this guide https://firebase.google.com/docs/firestore/quickstart#create No need to follow other steps, they are already implemented in the app.
 - Follow instructions in our [firebase repo](https://github.com/hypertrack/ridesharing-firebase) to setup Firebase Cloud Functions that act as a backend, interacting with HyperTrack APIs.
 - Note that Firebase Cloud Firestore and Cloud Functions are _not required_ to use HyperTrack SDKs. You may have your own server that is connected to your apps.

### 4. Run the apps

- You can run the Rider app in Simulator, but Driver app needs to be run on-device due to Simulator's lack of motion hardware.
- Being able to run the apps and signup means that the whole setup works.
- In these samples apps, Driver app creates actions for pickup and drop, which are tracked by Driver & Rider apps. See [architecture](#architecture) for details.

## Documentation
For detailed documentation of the APIs, customizations and what all you can build using HyperTrack, please visit the official [docs](https://www.hypertrack.com/docs/).

## Contribute
Feel free to clone, use, and contribute back via [pull requests](https://help.github.com/articles/about-pull-requests/). We'd love to see your pull requests - send them in! Please use the [issues tracker](https://github.com/hypertrack/ridesharing-ios/issues) to raise bug reports and feature requests.

We are excited to see what live location feature you build in your app using this project. Do ping us at help@hypertrack.com once you build one, and we would love to feature your app on our blog!

## Support
Join our [Slack community](https://join.slack.com/t/hypertracksupport/shared_invite/enQtNDA0MDYxMzY1MDMxLTdmNDQ1ZDA1MTQxOTU2NTgwZTNiMzUyZDk0OThlMmJkNmE0ZGI2NGY2ZGRhYjY0Yzc0NTJlZWY2ZmE5ZTA2NjI) for instant responses. You can also email us at help@hypertrack.com.
