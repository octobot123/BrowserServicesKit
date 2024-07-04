//
//  PrivacyDashboardURLBuilder.swift
//  DuckDuckGo
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

final class PrivacyDashboardURLBuilder {

    enum Constant {

        static let screenKey = "screen"
        static let breakageScreenKey = "breakageScreen"
        static let openerKey = "opener"
        static let categoryKey = "category"

        static let menuScreenKey = "menu"
        static let dashboardScreenKey = "dashboard"

    }

    enum Configuration {

        case startScreen(entryPoint: PrivacyDashboardEntryPoint, variant: PrivacyDashboardVariant)
        case segueToScreen(_ screen: Screen, entryPoint: PrivacyDashboardEntryPoint)

        func addScreenParameter(to url: URL) -> URL {
            var screen: Screen
            switch self {
            case .startScreen(let entryPoint, let variant):
                screen = entryPoint.screen(for: variant)
            case .segueToScreen(let destinationScreen, _):
                screen = destinationScreen
            }
            return url.appendingParameter(name: Constant.screenKey, value: screen.rawValue)
        }

        func addBreakageScreenParameterIfNeeded(to url: URL) -> URL {
            if case .startScreen(_, let variant) = self, let breakageScreen = variant.breakageScreen?.rawValue {
                return url.appendingParameter(name: Constant.breakageScreenKey, value: breakageScreen)
            }
            return url
        }

        func addCategoryParameterIfNeeded(to url: URL) -> URL {
            if case .startScreen(let entryPoint, _) = self, case .afterTogglePrompt(let category, _) = entryPoint {
                return url.appendingParameter(name: Constant.categoryKey, value: category)
            }
            return url
        }

        func addOpenerParameterIfNeeded(to url: URL) -> URL {
            if case .startScreen(let entryPoint, _) = self, case .toggleReport = entryPoint {
                return url.appendingParameter(name: Constant.openerKey, value: Constant.menuScreenKey)
            }
            if case .segueToScreen(_, let entryPoint) = self, entryPoint == .dashboard {
                return url.appendingParameter(name: Constant.openerKey, value: Constant.dashboardScreenKey)
            }
            return url
        }

    }

    private var url: URL
    private let configuration: Configuration

    init(configuration: Configuration) {
        guard let baseURL = Bundle.privacyDashboardURL else { fatalError() }
        self.url = baseURL
        self.configuration = configuration
    }

    func build() -> URL {
        url = configuration.addScreenParameter(to: url)
        url = configuration.addBreakageScreenParameterIfNeeded(to: url)
        url = configuration.addCategoryParameterIfNeeded(to: url)
        url = configuration.addOpenerParameterIfNeeded(to: url)
        return url
    }

}

private extension PrivacyDashboardVariant {

    var breakageScreen: BreakageScreen? {
        switch self {
        case .control: return nil
        case .a: return .categorySelection
        case .b: return .categoryTypeSelection
        }
    }

}
