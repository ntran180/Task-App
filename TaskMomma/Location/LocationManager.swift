//
//  LocationManager.swift
//  TaskMomma
//
//  Created by Nam Tran on 3/10/26.
//

import Foundation
import CoreLocation

enum LocationType: String, Codable, CaseIterable{
    case home = "Home"
    case school = "School"
    case work = "Work"
    case custom = "Custom"
}

struct TaskLocation: Codable, Hashable {
    var type: LocationType
    var customName: String?
    var latitude: Double?
    var longitude: Double?

    var displayName: String {
        type == .custom ? (customName ?? "Custom") : type.rawValue
    }

    func isNearby(to userLocation: CLLocation, within meters: Double = 500) -> Bool {
        guard let lat = latitude, let lon = longitude else { return false }
        return userLocation.distance(from: CLLocation(latitude: lat, longitude: lon)) <= meters
    }
}



class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

     @Published var currentLocation: CLLocation?
     @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            startTracking()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

