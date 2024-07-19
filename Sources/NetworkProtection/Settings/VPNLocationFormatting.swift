//
//  VPNLocationFormatting.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import SwiftUI

public protocol VPNLocationFormatting {
    func emoji(for country: String?,
               preferredLocation: VPNSettings.SelectedLocation) -> String?

    func string(from location: String?,
                preferredLocation: VPNSettings.SelectedLocation) -> String

    @available(macOS 12, iOS 15, *)
    func string(from location: String?,
                preferredLocation: VPNSettings.SelectedLocation,
                locationTextColor: Color,
                preferredLocationTextColor: Color) -> AttributedString
}
