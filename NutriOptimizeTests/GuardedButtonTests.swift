import XCTest
@testable import NutriOptimize

@MainActor
final class GuardedButtonTests: XCTestCase {

    func testDefaultCooldownIsHalfSecond() {
        XCTAssertEqual(TapActionGuard.defaultCooldown, 0.5)
        let guardObj = TapActionGuard()
        XCTAssertEqual(guardObj.cooldown, 0.5)
    }

    func testRapidTapsWithinCooldownAreBlocked() {
        var now: TimeInterval = 100.0
        let tapGuard = TapActionGuard(clock: { now })
        var count = 0

        XCTAssertTrue(tapGuard.perform { count += 1 })
        XCTAssertFalse(tapGuard.perform { count += 1 })

        now += 0.49
        XCTAssertFalse(tapGuard.perform { count += 1 })
        XCTAssertEqual(count, 1)

        now += 0.01
        XCTAssertTrue(tapGuard.perform { count += 1 })
        XCTAssertEqual(count, 2)
    }

    func testZeroCooldownOptsOutOfThrottling() {
        let now: TimeInterval = 100.0
        let tapGuard = TapActionGuard(cooldown: 0, clock: { now })
        var count = 0

        XCTAssertTrue(tapGuard.perform { count += 1 })
        XCTAssertTrue(tapGuard.perform { count += 1 })
        XCTAssertTrue(tapGuard.perform { count += 1 })
        XCTAssertEqual(count, 3)
    }

    func testZeroOverrideCooldownOptsOutWhenDefaultIsActive() {
        let now: TimeInterval = 100.0
        let tapGuard = TapActionGuard(cooldown: 0.5, clock: { now })
        var count = 0

        XCTAssertTrue(tapGuard.perform(cooldown: 0) { count += 1 })
        XCTAssertTrue(tapGuard.perform(cooldown: 0) { count += 1 })
        XCTAssertEqual(count, 2)
    }

    func testSingleFlightLockBlocksUntilEnded() {
        let tapGuard = TapActionGuard(cooldown: 0, clock: { 100.0 })

        XCTAssertTrue(tapGuard.beginSingleFlight())
        XCTAssertTrue(tapGuard.isInFlight)
        XCTAssertFalse(tapGuard.beginSingleFlight())
        XCTAssertFalse(tapGuard.shouldAllowTap())

        tapGuard.endSingleFlight()
        XCTAssertFalse(tapGuard.isInFlight)
        XCTAssertTrue(tapGuard.beginSingleFlight())
    }

    func testResetClearsCooldownAndSingleFlightState() {
        let tapGuard = TapActionGuard(cooldown: 0.5, clock: { 100.0 })

        XCTAssertTrue(tapGuard.shouldAllowTap())
        XCTAssertTrue(tapGuard.beginSingleFlight())
        XCTAssertFalse(tapGuard.shouldAllowTap())

        tapGuard.reset()
        XCTAssertFalse(tapGuard.isInFlight)
        XCTAssertTrue(tapGuard.shouldAllowTap())
    }
}
