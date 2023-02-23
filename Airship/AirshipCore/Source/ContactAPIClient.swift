/* Copyright Airship and Contributors */

import Foundation

// NOTE: For internal use only. :nodoc:
protocol ContactsAPIClientProtocol {
    func resolve(
        channelID: String
    ) async throws ->  AirshipHTTPResponse<ContactAPIResponse>

    func identify(
        channelID: String,
        namedUserID: String,
        contactID: String?
    ) async throws ->  AirshipHTTPResponse<ContactAPIResponse>

    func reset(
        channelID: String
    ) async throws ->  AirshipHTTPResponse<ContactAPIResponse>

    func update(
        identifier: String,
        tagGroupUpdates: [TagGroupUpdate]?,
        attributeUpdates: [AttributeUpdate]?,
        subscriptionListUpdates: [ScopedSubscriptionListUpdate]?
    ) async throws ->  AirshipHTTPResponse<Void>

    func associateChannel(
        identifier: String,
        channelID: String,
        channelType: ChannelType
    ) async throws ->  AirshipHTTPResponse<AssociatedChannel>

    func registerEmail(
        identifier: String,
        address: String,
        options: EmailRegistrationOptions
    ) async throws ->  AirshipHTTPResponse<AssociatedChannel>

    func registerSMS(
        identifier: String,
        msisdn: String,
        options: SMSRegistrationOptions
    ) async throws ->  AirshipHTTPResponse<AssociatedChannel>

    func registerOpen(
        identifier: String,
        address: String,
        options: OpenRegistrationOptions
    ) async throws ->  AirshipHTTPResponse<AssociatedChannel>

    func fetchSubscriptionLists(
        _ identifier: String
    ) async throws ->  AirshipHTTPResponse<[String: [ChannelScope]]>
}

// NOTE: For internal use only. :nodoc:
class ContactAPIClient: ContactsAPIClientProtocol {
    private static let path = "/api/contacts"
    private static let channelsPath = "/api/channels"

    private static let subscriptionListPath =
        "/api/subscription_lists/contacts/"

    private static let channelIDKey = "channel_id"
    private static let namedUserIDKey = "named_user_id"
    private static let contactIDKey = "contact_id"
    private static let deviceTypeKey = "device_type"
    private static let channelKey = "channel"
    private static let typeKey = "type"
    private static let commercialOptedInKey = "commercial_opted_in"
    private static let commercialOptedOutKey = "commercial_opted_out"
    private static let transactionalOptedInKey = "transactional_opted_in"
    private static let transactionalOptedOutKey = "transactional_opted_out"
    private static let optInModeKey = "opt_in_mode"
    private static let propertiesKey = "properties"
    private static let addressKey = "address"
    private static let msisdnKey = "msisdn"
    private static let senderKey = "sender"
    private static let optedInKey = "opted_in"
    private static let timezoneKey = "timezone"
    private static let localeCountryKey = "locale_country"
    private static let localeLanguageKey = "locale_language"
    private static let identifiersKey = "identifiers"
    private static let openKey = "open"
    private static let openPlatformName = "open_platform_name"
    private static let optInKey = "opt_in"
    private static let associateKey = "associate"

    private let config: RuntimeConfig
    private let session: AirshipRequestSession
    private let localeManager: AirshipLocaleManager

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(config: RuntimeConfig, session: AirshipRequestSession) {
        self.config = config
        self.session = session
        self.localeManager = AirshipLocaleManager(
            dataStore: PreferenceDataStore(appKey: config.appKey)
        )
    }

    convenience init(config: RuntimeConfig) {
        self.init(config: config, session: AirshipRequestSession(appKey: config.appKey))
    }
    
    func resolve(
        channelID: String
    ) async throws ->  AirshipHTTPResponse<ContactAPIResponse> {
        AirshipLogger.debug("Resolving contact with channel ID \(channelID)")
        
        guard let deviceAPIURL = config.deviceAPIURL else {
            throw AirshipErrors.error("The deviceAPI URL is nil")
        }
        
        let payload: [String: String] = [
            ContactAPIClient.channelIDKey: channelID,
            ContactAPIClient.deviceTypeKey: "ios",
        ]
        
        let request = self.request(
            payload,
            "\(deviceAPIURL)\(ContactAPIClient.path)/resolve"
        )
        
        return try await session.performHTTPRequest(
            request) { (data, response) in
                if response.statusCode == 200 {
                    do {
                        guard data != nil else {
                            throw AirshipErrors.error("Missing body")
                        }
                        
                        let jsonResponse =
                        try JSONSerialization.jsonObject(
                            with: data!,
                            options: .allowFragments
                        ) as? [AnyHashable: Any]
                        guard
                            let contactID = jsonResponse?["contact_id"]
                                as? String
                        else {
                            throw AirshipErrors.error("Missing contact_id")
                        }
                        guard
                            let isAnonymous = jsonResponse?["is_anonymous"]
                                as? Bool
                        else {
                            throw AirshipErrors.error("Missing is_anonymous")
                        }
                        
                        AirshipLogger.debug(
                            "Resolved contact with response: \(response)"
                        )
                        let contactDataResponse = ContactAPIResponse(
                            contactID: contactID,
                            isAnonymous: isAnonymous
                        )
                        return contactDataResponse
                    } catch {
                        throw AirshipErrors.error("Invalid response body \(String(describing: data))")
                    }
                } else {
                    let contactDataResponse = ContactAPIResponse(
                        contactID: nil,
                        isAnonymous: false
                    )
                    return contactDataResponse
                }
            }
    }
    
    func identify(
        channelID: String,
        namedUserID: String,
        contactID: String?
    ) async throws ->  AirshipHTTPResponse<ContactAPIResponse> {
        AirshipLogger.debug("Identifying contact with channel ID \(channelID)")
        
        guard let deviceAPIURL = config.deviceAPIURL else {
            throw AirshipErrors.error("The deviceAPI URL is nil")
        }
        
        var payload: [String: String] = [
            ContactAPIClient.channelIDKey: channelID,
            ContactAPIClient.namedUserIDKey: namedUserID,
            ContactAPIClient.deviceTypeKey: "ios",
        ]
        
        if contactID != nil {
            payload[ContactAPIClient.contactIDKey] = contactID
        }
        
        let request = self.request(
            payload,
            "\(deviceAPIURL)\(ContactAPIClient.path)/identify"
        )
        
        return try await session.performHTTPRequest(
            request) { (data, response) in
                if response.statusCode == 200 {
                    do {
                        guard data != nil else {
                            throw AirshipErrors.error("Missing body")
                        }
                        
                        let jsonResponse =
                        try JSONSerialization.jsonObject(
                            with: data!,
                            options: .allowFragments
                        ) as? [AnyHashable: Any]
                        guard
                            let contactID = jsonResponse?["contact_id"]
                                as? String
                        else {
                            throw AirshipErrors.error("Missing contact_id")
                        }
                        
                        AirshipLogger.debug(
                            "Identified contact with response: \(response)"
                        )
                        let contactDataResponse = ContactAPIResponse(
                            contactID: contactID,
                            isAnonymous: false
                        )
                        return contactDataResponse
                    } catch {
                        throw AirshipErrors.error("Invalid response body \(String(describing: data))")
                    }
                } else {
                    let contactDataResponse = ContactAPIResponse(
                        contactID: nil,
                        isAnonymous: false
                    )
                    return contactDataResponse
                }
            }
    }
    
    func reset(
        channelID: String
    ) async throws ->  AirshipHTTPResponse<ContactAPIResponse> {
        AirshipLogger.debug("Resetting contact with channel ID \(channelID)")
        
        guard let deviceAPIURL = config.deviceAPIURL else {
            throw AirshipErrors.error("The deviceAPI URL is nil")
        }
        
        let payload: [String: String] = [
            ContactAPIClient.channelIDKey: channelID,
            ContactAPIClient.deviceTypeKey: "ios",
        ]
        
        let request = self.request(
            payload,
            "\(deviceAPIURL)\(ContactAPIClient.path)/reset"
        )
        
        return try await session.performHTTPRequest(
            request) { (data, response) in
                if response.statusCode == 200 {
                    do {
                        guard data != nil else {
                            throw AirshipErrors.error("Missing body")
                        }
                        
                        let jsonResponse =
                        try JSONSerialization.jsonObject(
                            with: data!,
                            options: .allowFragments
                        ) as? [AnyHashable: Any]
                        guard
                            let contactID = jsonResponse?["contact_id"]
                                as? String
                        else {
                            throw AirshipErrors.error("Missing contact_id")
                        }
                        
                        AirshipLogger.debug(
                            "Reset contact with response: \(response)"
                        )
                        let contactDataResponse = ContactAPIResponse(
                            contactID: contactID,
                            isAnonymous: false
                        )
                        return contactDataResponse
                    } catch {
                        throw AirshipErrors.error("Invalid response body \(String(describing: data))")
                    }
                } else {
                    let contactDataResponse = ContactAPIResponse(
                        contactID: nil,
                        isAnonymous: false
                    )
                    return contactDataResponse
                }
            }
    }
    
    func update(
        identifier: String,
        tagGroupUpdates: [TagGroupUpdate]?,
        attributeUpdates: [AttributeUpdate]?,
        subscriptionListUpdates: [ScopedSubscriptionListUpdate]?
    ) async throws ->  AirshipHTTPResponse<Void> {
        AirshipLogger.debug("Updating contact with identifier \(identifier)")
        
        guard let deviceAPIURL = config.deviceAPIURL else {
            throw AirshipErrors.error("The deviceAPI URL is nil")
        }
        
        var payload: [String: Any] = [:]
        
        if let attributeUpdates = attributeUpdates, !attributeUpdates.isEmpty {
            payload["attributes"] = map(attributeUpdates: attributeUpdates)
        }
        
        if let tagGroupUpdates = tagGroupUpdates, !tagGroupUpdates.isEmpty {
            payload["tags"] = map(tagUpdates: tagGroupUpdates)
        }
        
        if let subscriptionListUpdates = subscriptionListUpdates,
           !subscriptionListUpdates.isEmpty
        {
            payload["subscription_lists"] = map(
                subscriptionListUpdates: subscriptionListUpdates
            )
        }
        
        let request = self.request(
            payload,
            "\(deviceAPIURL)/api/contacts/\(identifier)"
        )
        
        return try await session.performHTTPRequest(
            request) { (data, response) in
                AirshipLogger.debug(
                    "Update finished with response: \(response)"
                )
                
                return nil
            }
    }
    
    func associateChannel(
        identifier: String,
        channelID: String,
        channelType: ChannelType
    ) async throws ->  AirshipHTTPResponse<AssociatedChannel> {
        
        AirshipLogger.debug(
            "Associate channel \(channelID) with contact \(identifier)"
        )
        
        guard let deviceAPIURL = config.deviceAPIURL else {
            throw AirshipErrors.error("The deviceAPI URL is nil")
        }
        
        let payload: [String: Any] = [
            ContactAPIClient.associateKey: [
                [
                    ContactAPIClient.deviceTypeKey: channelType.stringValue,
                    ContactAPIClient.channelIDKey: channelID,
                ]
            ]
        ]
        
        let request = self.request(
            payload,
            "\(deviceAPIURL)/api/contacts/\(identifier)"
        )
        
        return try await session.performHTTPRequest(request) { data, response in
            AirshipLogger.debug(
                "Associate channel finished with response: \(response)"
            )
            if response.statusCode == 200 {
                let channel = AssociatedChannel(
                    channelType: channelType,
                    channelID: channelID
                )
                return channel
            } else {
                return nil
            }
        }
    }
    
    func registerEmail(
        identifier: String,
        address: String,
        options: EmailRegistrationOptions
    ) async throws ->  AirshipHTTPResponse<AssociatedChannel> {
        guard let deviceAPIURL = config.deviceAPIURL else {
            throw AirshipErrors.error("The deviceAPI URL is nil")
        }
        
        let currentLocale = self.localeManager.currentLocale
        
        var channelPayload: [String: Any] = [
            ContactAPIClient.typeKey: "email",
            ContactAPIClient.addressKey: address,
            ContactAPIClient.timezoneKey: TimeZone.current.identifier,
            ContactAPIClient.localeCountryKey: currentLocale.regionCode ?? "",
            ContactAPIClient.localeLanguageKey: currentLocale.languageCode
            ?? "",
        ]
        
        let formatter = AirshipUtils.isoDateFormatterUTCWithDelimiter()
        if let transactionalOptedIn = options.transactionalOptedIn {
            channelPayload[ContactAPIClient.transactionalOptedInKey] =
            formatter.string(from: transactionalOptedIn)
        }
        
        if let commercialOptedIn = options.commercialOptedIn {
            channelPayload[ContactAPIClient.commercialOptedInKey] =
            formatter.string(
                from: commercialOptedIn
            )
        }
        
        var payload: [String: Any] = [
            ContactAPIClient.channelKey: channelPayload,
            ContactAPIClient.optInModeKey: options.doubleOptIn
            ? "double" : "classic",
        ]
        
        if let properties = options.properties {
            payload[ContactAPIClient.propertiesKey] = properties.value()
        }
        
        let request = self.request(
            payload,
            "\(deviceAPIURL)\(ContactAPIClient.channelsPath)/restricted/email"
        )
        
        AirshipLogger.debug("Creating an Email channel with address \(address)")
        return try await registerChannel(
            identifier,
            request: request,
            channelType: .email
        )
        
    }
    
    func registerSMS(
        identifier: String,
        msisdn: String,
        options: SMSRegistrationOptions
    ) async throws ->  AirshipHTTPResponse<AssociatedChannel> {
        guard let deviceAPIURL = config.deviceAPIURL else {
            throw AirshipErrors.error("The deviceAPI URL is nil")
        }
        
        let currentLocale = self.localeManager.currentLocale
        let payload: [String: Any] = [
            ContactAPIClient.msisdnKey: msisdn,
            ContactAPIClient.senderKey: options.senderID,
            ContactAPIClient.timezoneKey: TimeZone.current.identifier,
            ContactAPIClient.localeCountryKey: currentLocale.regionCode ?? "",
            ContactAPIClient.localeLanguageKey: currentLocale.languageCode
            ?? "",
        ]
        
        let request = self.request(
            payload,
            "\(deviceAPIURL)\(ContactAPIClient.channelsPath)/restricted/sms"
        )
        
        AirshipLogger.debug(
            "Registering an SMS channel with msisdn \(msisdn) and sender \(options.senderID)"
        )
        return try await registerChannel(
            identifier,
            request: request,
            channelType: .sms
        )
    }
    
    func registerOpen(
        identifier: String,
        address: String,
        options: OpenRegistrationOptions
    ) async throws ->  AirshipHTTPResponse<AssociatedChannel> {
        guard let deviceAPIURL = config.deviceAPIURL else {
            throw AirshipErrors.error("The deviceAPI URL is nil")
        }
        
        let currentLocale = self.localeManager.currentLocale
        
        var openPayload: [String: Any] = [
            ContactAPIClient.openPlatformName: options.platformName
        ]
        
        if let identifiers = options.identifiers {
            var identifiersPayload: [String: Any] = [:]
            for (key, value) in identifiers {
                identifiersPayload[key] = value
            }
            openPayload[ContactAPIClient.identifiersKey] = identifiersPayload
        }
        
        let payload: [String: Any] = [
            ContactAPIClient.channelKey: [
                ContactAPIClient.typeKey: "open",
                ContactAPIClient.addressKey: address,
                ContactAPIClient.timezoneKey: TimeZone.current.identifier,
                ContactAPIClient.localeCountryKey: currentLocale.regionCode
                ?? "",
                ContactAPIClient.localeLanguageKey: currentLocale.languageCode
                ?? "",
                ContactAPIClient.optInKey: true,
                ContactAPIClient.openKey: openPayload,
            ]
        ]
        
        let request = self.request(
            payload,
            "\(deviceAPIURL)\(ContactAPIClient.channelsPath)/restricted/open"
        )
        
        AirshipLogger.debug(
            "Registering an open channel with address \(address)"
        )
        return try await registerChannel(
            identifier,
            request: request,
            channelType: .open
        )
    }
    
    private func registerChannel(
        _ identifier: String,
        request: AirshipRequest,
        channelType: ChannelType
    ) async throws ->  AirshipHTTPResponse<AssociatedChannel> {
        
        var channelID: String? = nil
        let response: AirshipHTTPResponse<AssociatedChannel> = try await session.performHTTPRequest(
            request) { (data, response) in
                AirshipLogger.debug(
                    "Contact channel \(channelType) created with response: \(response)"
                )
                guard response.statusCode == 200 || response.statusCode == 201
                else {
                    return nil
                }
                
                do {
                    guard let parsedChannelID = try self.parseChannelID(data: data)
                    else {
                        throw AirshipErrors.error("Missing channel ID")
                    }
                    channelID = parsedChannelID
                } catch {
                    throw AirshipErrors.error("Invalid response body \(String(describing: data))")
                }
                return nil
            }
        if let channelID = channelID {
            return try await self.associateChannel(identifier: identifier,
                                                   channelID: channelID,
                                                   channelType: channelType)
        } else {
            return response
        }
    }
    
    private func parseChannelID(data: Data?) throws -> String? {
        guard let data = data else {
            return nil
        }
        
        let jsonResponse =
        try JSONSerialization.jsonObject(
            with: data,
            options: .allowFragments
        )
        as? [AnyHashable: Any]
        
        return jsonResponse?["channel_id"] as? String
    }
    
    private func request(_ payload: [AnyHashable: Any], _ urlString: String)
    -> AirshipRequest
    {
        return AirshipRequest(
            url:  URL(string: urlString),
            headers: [
                "Accept":  "application/vnd.urbanairship+json; version=3;",
                "Content-Type": "application/json"
            ],
            method: "POST",
            auth: .basic(config.appKey, config.appSecret),
            body: try? JSONUtils.data(payload, options: [])
        )
    }
    
    private func map(subscriptionListUpdates: [ScopedSubscriptionListUpdate])
    -> [[AnyHashable: Any]]
    {
        return AudienceUtils.collapse(subscriptionListUpdates)
            .map {
                (list) -> ([AnyHashable: Any]) in
                var action: String
                switch list.type {
                case .subscribe:
                    action = "subscribe"
                case .unsubscribe:
                    action = "unsubscribe"
                }
                return [
                    "action": action,
                    "list_id": list.listId,
                    "scope": list.scope.stringValue,
                    "timestamp": AirshipUtils.isoDateFormatterUTCWithDelimiter()
                        .string(
                            from: list.date
                        ),
                ]
            }
    }
    
    private func map(attributeUpdates: [AttributeUpdate]) -> [[AnyHashable:
                                                                Any]]
    {
        return AudienceUtils.collapse(attributeUpdates)
            .compactMap {
                (attribute) -> ([AnyHashable: Any]?) in
                switch attribute.type {
                case .set:
                    guard let value = attribute.jsonValue?.value() else {
                        return nil
                    }
                    
                    return [
                        "action": "set",
                        "key": attribute.attribute,
                        "value": value,
                        "timestamp": AirshipUtils.isoDateFormatterUTCWithDelimiter()
                            .string(
                                from: attribute.date
                            ),
                    ]
                case .remove:
                    return [
                        "action": "remove",
                        "key": attribute.attribute,
                        "timestamp": AirshipUtils.isoDateFormatterUTCWithDelimiter()
                            .string(
                                from: attribute.date
                            ),
                    ]
                }
            }
    }
    
    private func map(tagUpdates: [TagGroupUpdate]) -> [AnyHashable: Any] {
        var tagsPayload: [String: [String: [String]]] = [:]
        
        AudienceUtils.collapse(tagUpdates)
            .forEach { tagUpdate in
                switch tagUpdate.type {
                case .add:
                    if tagsPayload["add"] == nil {
                        tagsPayload["add"] = [:]
                    }
                    tagsPayload["add"]?[tagUpdate.group] = tagUpdate.tags
                    break
                case .remove:
                    if tagsPayload["remove"] == nil {
                        tagsPayload["remove"] = [:]
                    }
                    tagsPayload["remove"]?[tagUpdate.group] = tagUpdate.tags
                    break
                case .set:
                    if tagsPayload["set"] == nil {
                        tagsPayload["set"] = [:]
                    }
                    tagsPayload["set"]?[tagUpdate.group] = tagUpdate.tags
                    break
                }
            }
        
        return tagsPayload
    }
    
    func fetchSubscriptionLists(
        _ identifier: String
    ) async throws -> AirshipHTTPResponse<[String: [ChannelScope]]> {
        AirshipLogger.debug(
            "Retrieving subscription lists associated with a contact"
        )
        
        guard let deviceAPIURL = config.deviceAPIURL else {
            throw AirshipErrors.error("The deviceAPI URL is nil")
        }
        
        let request = AirshipRequest(
            url: URL(
                string:
                    "\(deviceAPIURL)\(ContactAPIClient.subscriptionListPath)\(identifier)"
            ),
            headers: [
                "Accept":  "application/vnd.urbanairship+json; version=3;"
            ],
            method: "GET",
            auth: .basic(config.appKey, config.appSecret)
        )
        
        return try await session.performHTTPRequest(
            request) { data, response in
                if response.statusCode == 200 {
                    AirshipLogger.debug(
                        "Retrieved lists with response: \(response)"
                    )
                    
                    do {
                        guard let data = data else {
                            throw AirshipErrors.error("Missing body")
                        }
                        
                        let parsedBody = try self.decoder.decode(
                            SubscriptionResponseBody.self,
                            from: data
                        )
                        let scopedLists =
                        try parsedBody.toScopedSubscriptionLists()
                        return scopedLists
                    } catch {
                        throw AirshipErrors.error("Invalid response body \(String(describing: data))")
                    }
                } else {
                    return nil
                }
            }
    }
}

struct ContactAPIResponse {
    let contactID: String?
    let isAnonymous: Bool?
}

internal struct SubscriptionResponseBody: Decodable {
    let subscriptionLists: [Entry]

    enum CodingKeys: String, CodingKey {
        case subscriptionLists = "subscription_lists"
    }

    struct Entry: Decodable, Equatable {
        let lists: [String]
        let scope: String

        enum CodingKeys: String, CodingKey {
            case lists = "list_ids"
            case scope = "scope"
        }
    }

    func toScopedSubscriptionLists() throws -> [String: [ChannelScope]] {
        var parsed: [String: [ChannelScope]] = [:]
        try self.subscriptionLists.forEach { entry in
            let scope = try ChannelScope.fromString(entry.scope)
            entry.lists.forEach { listID in
                var scopes = parsed[listID] ?? []
                if !scopes.contains(scope) {
                    scopes.append(scope)
                    parsed[listID] = scopes
                }
            }
        }
        return parsed
    }
}
