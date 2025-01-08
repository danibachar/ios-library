/* Copyright Airship and Contributors */

import XCTest
@testable import AirshipCore

final class MediaEventTemplateTest: XCTestCase {

    func testBrowsed() {
        let event = CustomEvent(mediaTemplate: .browsed)
        XCTAssertEqual("browsed_content", event.eventName)
        XCTAssertEqual("media", event.templateType)

        let expectedProperties: [String: AirshipJSON] = [ "ltv": .bool(false) ]
        XCTAssertEqual(expectedProperties, event.properties)
    }

    func testConsumed() {
        let event = CustomEvent(mediaTemplate: .consumed)
        XCTAssertEqual("consumed_content", event.eventName)
        XCTAssertEqual("media", event.templateType)

        let expectedProperties: [String: AirshipJSON] = [ "ltv": .bool(false) ]
        XCTAssertEqual(expectedProperties, event.properties)
    }

    func testShared() {
        let event = CustomEvent(mediaTemplate: .shared(source: "some source", medium: "some medium"))
        XCTAssertEqual("shared_content", event.eventName)
        XCTAssertEqual("media", event.templateType)

        let expectedProperties: [String: AirshipJSON] = [
            "ltv": .bool(false),
            "source": .string("some source"),
            "medium": .string("some medium")
        ]
        XCTAssertEqual(expectedProperties, event.properties)
    }

    func testSharedEmptyDetails() {
        let event = CustomEvent(mediaTemplate: .shared())
        XCTAssertEqual("shared_content", event.eventName)
        XCTAssertEqual("media", event.templateType)

        let expectedProperties: [String: AirshipJSON] = [ "ltv": .bool(false) ]
        XCTAssertEqual(expectedProperties, event.properties)
    }

    func testStarred() {
        let event = CustomEvent(mediaTemplate: .starred)
        XCTAssertEqual("starred_content", event.eventName)
        XCTAssertEqual("media", event.templateType)

        let expectedProperties: [String: AirshipJSON] = [ "ltv": .bool(false) ]
        XCTAssertEqual(expectedProperties, event.properties)
    }

    func testProperties() {
        let date = Date.now
        let properties = CustomEvent.MediaProperties(
            id: "some id",
            category: "some category",
            type: "some type",
            eventDescription: "some description",
            isLTV: true,
            author: "some author",
            publishedDate: date,
            isFeature: true
        )

        let event = CustomEvent(
            mediaTemplate: .shared(source: "some source", medium: "some medium"),
            properties: properties
        )
        XCTAssertEqual("shared_content", event.eventName)
        XCTAssertEqual("media", event.templateType)

        let expectedProperties: [String: AirshipJSON] = [
            "id": .string("some id"),
            "category": .string("some category"),
            "type": .string("some type"),
            "description": .string("some description"),
            "ltv": .bool(true),
            "author": .string("some author"),
            "published_date": try! AirshipJSON.wrap(date, encoder: CustomEvent.defaultEncoder()),
            "feature": .bool(true),
            "source": .string("some source"),
            "medium": .string("some medium")
        ]

        XCTAssertEqual(expectedProperties, event.properties)
    }
}
