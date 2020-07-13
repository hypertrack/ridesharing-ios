platform :ios, '13.0'
inhibit_all_warnings!
use_frameworks!

def hyperTrack_pods
  pod 'HyperTrack', "4.2.1"
  pod 'HyperTrackViews/MapKit', "0.5.1"
end

def fireStore_pods
  pod 'Firebase/Core'
  pod 'Firebase/Firestore'
  pod 'FirebaseFirestoreSwift'
end

target 'Driver' do
  hyperTrack_pods
  fireStore_pods
end

target 'Rider' do
  hyperTrack_pods
  fireStore_pods
end

target 'HyperTrackHelper' do
  hyperTrack_pods
end

target 'CommonModels' do
  hyperTrack_pods
end

target 'AppState' do
  hyperTrack_pods
end
