//
//  WDSPExtensionMainView.swift
//  WDSPExtension
//
//  Created by HAWZHIN on 27/02/2025.
//

import SwiftUI

struct WDSPExtensionMainView: View {
    var parameterTree: ObservableAUParameterGroup
    
    var body: some View {
        ParameterSlider(param: parameterTree.global.gain)
    }
}
