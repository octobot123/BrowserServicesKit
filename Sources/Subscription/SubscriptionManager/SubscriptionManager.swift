//
//  SubscriptionManager.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
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
import Common
import Macros

public protocol SubscriptionManaging {
    var configuration: SubscriptionConfiguration { get }
    var accountManager: AccountManaging { get }
}

public final class SubscriptionManager: SubscriptionManaging {

    public var configuration: SubscriptionConfiguration
    public var accountManager: AccountManaging

    public init(configuration: SubscriptionConfiguration,
                accountManager: AccountManaging) {
//        self.subscriptionConfiguration = subscriptionConfiguration
        self.configuration = configuration
        self.accountManager = accountManager
    }

}


//public protocol SubscriptionURLProviding {
//    var subscriptionBaseURL: URL { get }
////    var subscriptionPurchase: URL { get }
//}
//
//public final class SubscriptionURLProvider: SubscriptionURLProviding {
//
//    public static var currentServiceEnvironment: ServiceEnvironment = .default
//
//    public enum ServiceEnvironment: String, Codable {
//        case production
//        case staging
//
//        public static var `default`: ServiceEnvironment = .production
//
//        public var description: String {
//            switch self {
//            case .production: return "Production"
//            case .staging: return "Staging"
//            }
//        }
//    }
//
//    public var subscriptionBaseURL: URL {
////        switch SubscriptionPurchaseEnvironment.currentServiceEnvironment {
////        case .production:
////            #URL("https://duckduckgo.com/subscriptions")
////        case .staging:
//            #URL("https://duckduckgo.com/subscriptions?environment=staging")
////        }
//    }
//
////    public var subscriptionPurchase: URL
//}


// MARK: -

//public protocol SubscriptionAccountManaging {
//    var accessToken: String? { get }
//}

// MARK: -

