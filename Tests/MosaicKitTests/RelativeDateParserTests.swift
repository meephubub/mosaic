import XCTest
@testable import MosaicKit

final class RelativeDateParserTests: XCTestCase {
    func testToday() {
        let parsed = RelativeDateParser.parse("today")
        XCTAssertNotNil(parsed)
        XCTAssertTrue(Calendar.current.isDateInToday(parsed!))
    }

    func testTomorrow() {
        let parsed = RelativeDateParser.parse("tomorrow")
        XCTAssertNotNil(parsed)
        XCTAssertTrue(Calendar.current.isDateInTomorrow(parsed!))
    }

    func testCaseInsensitive() {
        XCTAssertNotNil(RelativeDateParser.parse("Tomorrow"))
        XCTAssertNotNil(RelativeDateParser.parse("TMR"))
    }

    func testNilAndEmpty() {
        XCTAssertNil(RelativeDateParser.parse(nil))
        XCTAssertNil(RelativeDateParser.parse(""))
    }

    func testNextWeekday() {
        let parsed = RelativeDateParser.parse("next monday")
        XCTAssertNotNil(parsed)
        // Must be a Monday in the future.
        XCTAssertEqual(Calendar.current.component(.weekday, from: parsed!), 2)
        XCTAssertGreaterThan(parsed!, Date.now)
    }

    func testInDays() {
        let parsed = RelativeDateParser.parse("in 3 days")
        XCTAssertNotNil(parsed)
        let days = Calendar.current.dateComponents(
            [.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: parsed!)
        ).day
        XCTAssertEqual(days, 3)
    }

    func testInWeeks() {
        let parsed = RelativeDateParser.parse("in 2 weeks")
        XCTAssertNotNil(parsed)
        let days = Calendar.current.dateComponents(
            [.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: parsed!)
        ).day
        XCTAssertEqual(days, 14)
    }

    func testUnknownPhraseReturnsNil() {
        XCTAssertNil(RelativeDateParser.parse("someday maybe"))
    }
}
