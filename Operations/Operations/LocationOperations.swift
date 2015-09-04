//
//  LocationOperations.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CoreLocation

@availability(*, unavailable, renamed="UserLocationOperation")
public typealias LocationOperation = UserLocationOperation

/**
    An `Operation` subclass to request the user's current
    geographic location.
*/
public class UserLocationOperation: Operation {
    public typealias LocationResponseHandler = (location: CLLocation) -> Void
    private typealias LocationManagerConfiguration = (LocationManager) -> Void

    public enum Error: ErrorType, Equatable {
        case LocationManagerDidFail(NSError)
    }

    private let accuracy: CLLocationAccuracy
    private var manager: LocationManager?
    private let handler: LocationResponseHandler

    /**
        This is the true public API, the other public initializer is really just a testing
        interface, and will not be public in Swift 2.0, Operations 2.0
    */
    public convenience init(accuracy: CLLocationAccuracy = kCLLocationAccuracyThreeKilometers, handler: LocationResponseHandler) {
        self.init(accuracy: accuracy, manager: .None, handler: handler)
    }

    /**
        This is a testing interface, and will not be public in Swift 2.0, Operations 2.0.
        Instead use init(:CLLocationAccuracy, handler: LocationResponseHandler)
    */
    public init(accuracy: CLLocationAccuracy, manager: LocationManager? = .None, handler: LocationResponseHandler) {
        self.accuracy = accuracy
        self.manager = manager
        self.handler = handler
        super.init()
        addCondition(LocationCondition(usage: .WhenInUse, manager: manager))
        addCondition(MutuallyExclusive<LocationManager>())
    }

    public override func execute() {

        let configureLocationManager: LocationManagerConfiguration = { manager in
            manager.opr_setDesiredAccuracy(self.accuracy)
            manager.opr_setDelegate(self)
            manager.opr_startUpdatingLocation()
        }

        if var manager = manager {
            configureLocationManager(manager)
        }
        else {
            dispatch_async(Queue.Main.queue) {
                let manager = CLLocationManager()
                configureLocationManager(manager)
                self.manager = manager as LocationManager
            }
        }
    }

    public override func cancel() {
        dispatch_async(Queue.Main.queue) {
            self.stopLocationUpdates()
            super.cancel()
        }
    }

    private func stopLocationUpdates() {
        manager?.opr_stopLocationUpdates()
        manager = .None
    }
}

extension UserLocationOperation: CLLocationManagerDelegate {

    public func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let locations = locations as? [CLLocation], location = locations.last where location.horizontalAccuracy <= accuracy {
            stopLocationUpdates()
            handler(location: location)
            finish()
        }
    }

    public func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        stopLocationUpdates()
        finish(Error.LocationManagerDidFail(error))
    }
}

public func ==(a: UserLocationOperation.Error, b: UserLocationOperation.Error) -> Bool {
    switch (a, b) {
    case let (.LocationManagerDidFail(aError), .LocationManagerDidFail(bError)):
        return aError == bError
    default: return false
    }
}

// MARK: - Geocoding



public protocol ReverseGeocoderType {
    func opr_cancel()
    func opr_reverseGeocodeLocation(location: CLLocation, completion: ([CLPlacemark], NSError?) -> Void)
}

extension CLGeocoder: ReverseGeocoderType {

    public func opr_cancel() {
        cancelGeocode()
    }

    public func opr_reverseGeocodeLocation(location: CLLocation, completion: ([CLPlacemark], NSError?) -> Void) {
        reverseGeocodeLocation(location) { (results, error) in
            completion(results as! [CLPlacemark], error as NSError?)
        }
    }
}

public class ReverseGeocodeOperation: Operation {

    public enum Error: ErrorType {
        case GeocoderError(NSError)
    }

    public let location: CLLocation
    internal let geocoder: ReverseGeocoderType

    public private(set) var placemark: CLPlacemark? = .None

    public init(location: CLLocation, geocoder: ReverseGeocoderType = CLGeocoder()) {
        self.location = location
        self.geocoder = geocoder
        super.init()
        name = "Reverse Geocode"
        addObserver(NetworkObserver())
        addObserver(BackgroundObserver())
    }

    public override func cancel() {
        geocoder.opr_cancel()
        super.cancel()
    }

    public override func execute() {
        geocoder.opr_reverseGeocodeLocation(location) { (results, error) in
            self.placemark = results.first
            self.finish(error.map { Error.GeocoderError($0) })
        }
    }
}



