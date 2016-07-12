//
//  MMLocationManager.swift
//
//  Created by Ivan Cigic on 06/07/16.
//
//

import Foundation
import CoreLocation
import UIKit

public protocol MMLocationManagerProtocol: class {
    func canAddCampaign(campaign: MMCampaign) -> Bool
    func willAddCampaing(campaign: MMCampaign)
    func didAddCampaing(campaign: MMCampaign)
    func didEnterRegion(region: MMRegion)
    func didExitRegion(region: MMRegion)
}

public class MMLocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Public
    
    public var locationManager: CLLocationManager
    public weak var delegate: MMLocationManagerProtocol?
    var datasource: MMGeofencingDatasource
    
    public var allCampaings: Set<MMCampaign> {
        return datasource.campaigns
    }
    
    public var allRegions: Set<MMRegion> {
        return datasource.regions
    }
    
    public override init() {
        //  Just create location manager.
        locationManager = CLLocationManager()
        datasource = MMGeofencingDatasource()
        super.init()
    }
    
    public func startMonitoringCampaigns() {
        self.locationManager.delegate = self
        self.locationManager.distanceFilter = kCLLocationAccuracyHundredMeters
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // When app is moving to the background stop standard location service and start
        // significant location change service if available.
        NSNotificationCenter.defaultCenter().addObserverForName(
            UIApplicationWillResignActiveNotification,
            object: nil,
            queue: nil,
            usingBlock:{
                [unowned self]
                note in
                if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                    self.locationManager.stopUpdatingLocation()
                    self.locationManager.startMonitoringSignificantLocationChanges()
                } else {
                    MMLogInfo("Significant location change monitoring is not available.")
                }
        })
        
        // When app is moving to the foreground stop the significatn location change
        // and start the stand
        NSNotificationCenter.defaultCenter().addObserverForName(
            UIApplicationWillEnterForegroundNotification,
            object: nil,
            queue: nil,
            usingBlock:{
                [unowned self]
                note in
                if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                    self.locationManager.stopMonitoringSignificantLocationChanges()
                    self.locationManager.startUpdatingLocation()
                } else {
                    MMLogInfo("Significant location change monitoring is not available.")
                }
        })
        
        // Load saved (already received) campaings and start monitoring them.
        startMonitoringCampaigns(datasource.campaigns)
    }
    
    public func addCampaingToRegionMonitoring(campaign: MMCampaign) {
        datasource.addNewCampaign(campaign)
        refreshMonitoredRegions()
    }
    
    public func removeCampaignFromRegionMonitoring(campaing: MMCampaign) {
        datasource.removeCampaign(campaing)
        refreshMonitoredRegions()
    }
    
    // MARK: - Private
    
    private func refreshMonitoredRegions() {
        let regions = locationManager.monitoredRegions
        for region in regions {
            locationManager.stopMonitoringForRegion(region)
        }
        
        for region in self.findTwentyClosestRegions(datasource.campaigns) {
            addRegionToMonitor(region)
        }
    }
    
    private func addRegionToMonitor(region: MMRegion) {
        if CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
            let newMonioredRegion = CLCircularRegion(center: region.center,
                                                     radius: region.radius,
                                                     identifier: region.id)
            newMonioredRegion.notifyOnEntry = true
            newMonioredRegion.notifyOnExit = true
            locationManager.startMonitoringForRegion(newMonioredRegion)
        }
    }
    
    private func removeRegionFromMonitoring(region: MMRegion) {
        // Get CLRegion
        let regions = locationManager.monitoredRegions.filter({
            $0.identifier == region.id
        })
        if let monitoredRegion = regions.first {
            locationManager.stopMonitoringForRegion(monitoredRegion)
        }
    }
    
    private func startMonitoringCampaigns(campaigns: Set<MMCampaign>) {
        let regions = locationManager.monitoredRegions
        for region in regions {
            locationManager.stopMonitoringForRegion(region)
        }
        for region in self.findTwentyClosestRegions(campaigns) {
            addRegionToMonitor(region)
        }
    }
    
    // Apple region monitor can monitor only 20 regions per application. If there are
    // more than 20 regions installed +to monitor we have to find 20 closest regions.
    private func findTwentyClosestRegions(campaigns: Set<MMCampaign>) ->  [MMRegion] {
        let allRegions: [MMRegion] = Array(datasource.regions)
        guard let currentLocation = self.locationManager.location else {
            return Array(allRegions[0..<min(20, allRegions.count)])
        }
        
        let sortedRegions = allRegions.sort( { (region1: MMRegion, region2: MMRegion) in
            let location1 = CLLocation(latitude: region1.center.latitude,
                longitude: region1.center.latitude)
            let location2 = CLLocation(latitude: region2.center.latitude,
                longitude: region2.center.latitude)
            return currentLocation.distanceFromLocation(location1) < currentLocation.distanceFromLocation(location2)
        })
        
        return Array(sortedRegions[0..<min(20, sortedRegions.count)])
    }
    
    // Received notification contains dictionary containing campaign details. Campaign details
    // contains general campaign details and array of regions to monitor.
    public class func getCampaignFromDictionary(geoDict: [String:AnyObject]) -> MMCampaign {
        let id = geoDict["id"] as? String ?? ""
        let title = geoDict["title"] as? String ?? ""
        let message = geoDict["message"] as? String ?? ""
        var newCampaing = MMCampaign(id: id, title: title, message: message)
        newCampaing.source = .Remote
        var regions: Set<MMRegion> = []
        let regArray = geoDict["regions"] as? [[String:AnyObject]] ?? []
        for regDict in regArray {
            let lat = regDict["latitude"] as? Double ?? 0
            let lon = regDict["longitude"] as? Double ?? 0
            let radius = regDict["radius"] as? Double ?? 0
            let loc = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            var newRegion = MMRegion(center: loc, radius: radius)
            newRegion.campaign = newCampaing
            regions.insert(newRegion)
        }
        newCampaing.regions = regions
        return newCampaing
    }
    
    // MARK: - Location Manager delegate
    
    public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Call delegate function on enter
        for campaing in MMGeofencingDatasource.sharedInstance.campaigns {
            for reg in campaing.regions {
                if reg.id == region.identifier {
                    delegate?.didEnterRegion(reg)
                }
            }
        }
    }
    
    public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        // Call delegate function on exit
        for campaing in MMGeofencingDatasource.sharedInstance.campaigns {
            for reg in campaing.regions {
                if reg.id == region.identifier {
                    delegate?.didExitRegion(reg)
                }
            }
        }
    }
}