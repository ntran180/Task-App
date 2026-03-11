//
//  LocationLabel.swift
//  TaskMomma
//
//  Created by Nam Tran on 3/10/26.
//

import SwiftUI

struct LocationLabel: View {
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        if let location = locationManager.currentLocation {
            Text("Location: \(location.coordinate.latitude, specifier: "%.4f"), \(location.coordinate.longitude, specifier: "%.4f")")
        } else {
            Text("Location: unavailable")
        }
    }
}

