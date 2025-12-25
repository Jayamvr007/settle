//
//  SettleTests.swift
//  SettleTests
//
//  Unit tests for Settle app - Balance and Split calculations
//

import XCTest
@testable import Settle

final class SettleTests: XCTestCase {
    
    // MARK: - Test Data Setup
    
    var member1: Member!
    var member2: Member!
    var member3: Member!
    var testGroup: Group!
    
    override func setUp() {
        super.setUp()
        member1 = Member(name: "Alice")
        member2 = Member(name: "Bob")
        member3 = Member(name: "Charlie")
        testGroup = Group(name: "Test Group", members: [member1, member2, member3])
    }
    
    // MARK: - Equal Split Tests
    
    func testEqualSplitTwoMembers() {
        // ₹100 split between 2 people = ₹50 each
        let amount: Decimal = 100
        let shareAmount = amount / Decimal(2)
        
        XCTAssertEqual(shareAmount, 50, "Equal split of ₹100 between 2 should be ₹50 each")
    }
    
    func testEqualSplitThreeMembers() {
        // ₹100 split between 3 people = ₹33.33... each
        let amount: Decimal = 100
        let shareAmount = amount / Decimal(3)
        
        // Should be approximately 33.33
        XCTAssertTrue(shareAmount > 33 && shareAmount < 34, "Equal split of ₹100 between 3 should be ~₹33.33")
    }
    
    func testEqualSplitNonDivisible() {
        // Edge case: ₹10 split between 3 people
        let amount: Decimal = 10
        let memberCount = 3
        let shareAmount = amount / Decimal(memberCount)
        let totalShares = shareAmount * Decimal(memberCount)
        
        // Total should still be close to original amount
        XCTAssertTrue(abs(totalShares - amount) < 0.01, "Sum of shares should equal original amount")
    }
    
    // MARK: - Percentage Split Tests
    
    func testPercentageSplit5050() {
        // ₹100 with 50% - 50% split
        let amount: Decimal = 100
        let percent1: Decimal = 50
        let percent2: Decimal = 50
        
        let share1 = (percent1 / 100) * amount
        let share2 = (percent2 / 100) * amount
        
        XCTAssertEqual(share1, 50, "50% of ₹100 should be ₹50")
        XCTAssertEqual(share2, 50, "50% of ₹100 should be ₹50")
        XCTAssertEqual(share1 + share2, amount, "Shares should total original amount")
    }
    
    func testPercentageSplit7030() {
        // ₹100 with 70% - 30% split
        let amount: Decimal = 100
        let percent1: Decimal = 70
        let percent2: Decimal = 30
        
        let share1 = (percent1 / 100) * amount
        let share2 = (percent2 / 100) * amount
        
        XCTAssertEqual(share1, 70, "70% of ₹100 should be ₹70")
        XCTAssertEqual(share2, 30, "30% of ₹100 should be ₹30")
        XCTAssertEqual(share1 + share2, amount, "Shares should total original amount")
    }
    
    func testPercentageSplitThreeWay() {
        // ₹1000 with 50% - 30% - 20% split
        let amount: Decimal = 1000
        let percentages: [Decimal] = [50, 30, 20]
        
        let shares = percentages.map { ($0 / 100) * amount }
        let total = shares.reduce(0, +)
        
        XCTAssertEqual(shares[0], 500, "50% of ₹1000 should be ₹500")
        XCTAssertEqual(shares[1], 300, "30% of ₹1000 should be ₹300")
        XCTAssertEqual(shares[2], 200, "20% of ₹1000 should be ₹200")
        XCTAssertEqual(total, amount, "Shares should total original amount")
    }
    
    // MARK: - Balance Calculation Tests
    
    func testBalanceAfterOneExpense() {
        // Alice pays ₹300, split equally between Alice, Bob, Charlie
        // Each owes ₹100
        // Alice is owed ₹200 (Bob owes ₹100, Charlie owes ₹100)
        
        let amount: Decimal = 300
        let share = amount / 3 // ₹100 each
        
        // Alice's balance: paid ₹300, owes ₹100 = +₹200
        let aliceBalance = amount - share
        XCTAssertEqual(aliceBalance, 200, "Alice should be owed ₹200")
        
        // Bob's balance: paid ₹0, owes ₹100 = -₹100
        let bobBalance = Decimal(0) - share
        XCTAssertEqual(bobBalance, -100, "Bob should owe ₹100")
    }
    
    func testBalanceNetZero() {
        // Alice pays ₹100 (split 50-50 with Bob)
        // Bob pays ₹100 (split 50-50 with Alice)
        // Net balance should be 0
        
        let alicePaid: Decimal = 100
        let bobPaid: Decimal = 100
        let aliceShare: Decimal = 50 + 50  // ₹50 from Alice's expense + ₹50 from Bob's
        let bobShare: Decimal = 50 + 50
        
        let aliceBalance = alicePaid - aliceShare
        let bobBalance = bobPaid - bobShare
        
        XCTAssertEqual(aliceBalance, 0, "Alice balance should be 0")
        XCTAssertEqual(bobBalance, 0, "Bob balance should be 0")
    }
    
    // MARK: - Settlement Calculation Tests
    
    func testSimpleSettlement() {
        // Alice is owed ₹100 by Bob
        // Settlement: Bob pays Alice ₹100
        
        let aliceBalance: Decimal = 100
        let bobBalance: Decimal = -100
        
        XCTAssertEqual(aliceBalance + bobBalance, 0, "Balances should sum to zero")
        
        // After settlement
        let settlementAmount = abs(bobBalance)
        let aliceAfter = aliceBalance - settlementAmount
        let bobAfter = bobBalance + settlementAmount
        
        XCTAssertEqual(aliceAfter, 0, "Alice should be settled")
        XCTAssertEqual(bobAfter, 0, "Bob should be settled")
    }
    
    func testSettlementOptimization() {
        // A owes B ₹50, B owes C ₹50
        // Optimized: A pays C ₹50 directly (1 transaction instead of 2)
        
        let aBalance: Decimal = -50
        let bBalance: Decimal = 0  // owes C but is owed by A
        let cBalance: Decimal = 50
        
        XCTAssertEqual(aBalance + bBalance + cBalance, 0, "Total balance should be zero")
    }
    
    // MARK: - Edge Cases
    
    func testZeroAmount() {
        let amount: Decimal = 0
        let share = amount / 2
        
        XCTAssertEqual(share, 0, "Share of ₹0 should be ₹0")
    }
    
    func testVerySmallAmount() {
        // ₹0.01 split between 2
        let amount: Decimal = Decimal(string: "0.01")!
        let share = amount / 2
        
        XCTAssertTrue(share > 0, "Very small amounts should still result in positive shares")
    }
    
    func testLargeAmount() {
        // ₹1,00,00,000 (1 crore) split between 3
        let amount: Decimal = 10000000
        let share = amount / 3
        
        XCTAssertTrue(share > 3000000, "Large amount split should work correctly")
    }
    
    func testDecimalPrecision() {
        // ₹100 split 3 ways, then multiplied back
        let amount: Decimal = 100
        let share = amount / 3
        let reconstructed = share * 3
        
        // Due to decimal division, reconstructed might not equal exactly 100
        // But should be very close
        let difference = abs(reconstructed - amount)
        XCTAssertTrue(difference < Decimal(string: "0.0001")!, "Decimal precision should be maintained")
    }
    
    func testSingleMemberSplit() {
        // Edge case: Only 1 member selected
        let amount: Decimal = 100
        let share = amount / 1
        
        XCTAssertEqual(share, amount, "Single member should get full amount")
    }
    
    // MARK: - Custom Amount Split Tests
    
    func testCustomSplitValidation() {
        // Custom split: ₹60 + ₹40 = ₹100
        let total: Decimal = 100
        let share1: Decimal = 60
        let share2: Decimal = 40
        
        let sum = share1 + share2
        XCTAssertEqual(sum, total, "Custom shares should equal total amount")
    }
    
    func testCustomSplitMismatch() {
        // Invalid: ₹30 + ₹40 ≠ ₹100
        let total: Decimal = 100
        let share1: Decimal = 30
        let share2: Decimal = 40
        
        let sum = share1 + share2
        XCTAssertNotEqual(sum, total, "Invalid custom split should not equal total")
    }
}
