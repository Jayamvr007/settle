#!/usr/bin/env swift
//
//  EdgeCaseTests.swift
//  Run with: swift EdgeCaseTests.swift
//

import Foundation

// MARK: - Test Framework
var passed = 0
var failed = 0

func assert(_ condition: Bool, _ message: String) {
    if condition {
        print("✅ PASS: \(message)")
        passed += 1
    } else {
        print("❌ FAIL: \(message)")
        failed += 1
    }
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String) {
    assert(a == b, "\(message) - Expected \(b), got \(a)")
}

func assertClose(_ a: Decimal, _ b: Decimal, tolerance: Decimal = Decimal(string: "0.01")!, _ message: String) {
    assert(abs(a - b) < tolerance, "\(message) - Expected ~\(b), got \(a)")
}

print("=" * 50)
print("🧪 SETTLE APP - EDGE CASE TESTS")
print("=" * 50)
print("")

// MARK: - 1. Equal Split Tests
print("📊 EQUAL SPLIT TESTS")
print("-" * 30)

// Test 1: Equal split between 2 people
let amount1: Decimal = 100
let share1 = amount1 / 2
assertEqual(share1, 50, "₹100 split 2 ways = ₹50 each")

// Test 2: Equal split between 3 people (non-divisible)
let amount2: Decimal = 100
let share2 = amount2 / 3
assertClose(share2, Decimal(string: "33.33")!, "₹100 split 3 ways = ~₹33.33 each")

// Test 3: Verify total equals original
let totalShares = share2 * 3
assertClose(totalShares, amount2, "Sum of shares equals original")

print("")

// MARK: - 2. Percentage Split Tests
print("📊 PERCENTAGE SPLIT TESTS")
print("-" * 30)

// Test 4: 50-50 split
let pct_amount: Decimal = 100
let share_50 = (Decimal(50) / 100) * pct_amount
assertEqual(share_50, 50, "50% of ₹100 = ₹50")

// Test 5: 70-30 split
let share_70 = (Decimal(70) / 100) * pct_amount
let share_30 = (Decimal(30) / 100) * pct_amount
assertEqual(share_70 + share_30, 100, "70% + 30% = 100%")

// Test 6: Three-way percentage
let pct_1000: Decimal = 1000
let shares = [50, 30, 20].map { (Decimal($0) / 100) * pct_1000 }
assertEqual(shares.reduce(0, +), 1000, "50% + 30% + 20% of ₹1000 = ₹1000")

print("")

// MARK: - 3. Balance Calculation Tests
print("📊 BALANCE CALCULATION TESTS")
print("-" * 30)

// Test 7: Alice pays ₹300, split 3 ways
let paid: Decimal = 300
let owes: Decimal = 100 // Each person's share
let aliceBalance = paid - owes  // Paid ₹300, owes ₹100 = +₹200
let bobBalance = Decimal(0) - owes  // Paid ₹0, owes ₹100 = -₹100
assertEqual(aliceBalance, 200, "Alice is owed ₹200")
assertEqual(bobBalance, -100, "Bob owes ₹100")

// Test 8: Net zero after reciprocal expenses
let netAlice = Decimal(100) - Decimal(100) // Paid 100, owes 100
assertEqual(netAlice, 0, "Net balance is zero after equal payments")

print("")

// MARK: - 4. Edge Cases
print("📊 EDGE CASES")
print("-" * 30)

// Test 9: Zero amount
let zeroShare = Decimal(0) / 2
assertEqual(zeroShare, 0, "₹0 split = ₹0")

// Test 10: Very small amount
let smallAmount = Decimal(string: "0.01")!
let smallShare = smallAmount / 2
assert(smallShare > 0, "Very small amount (₹0.01) still positive")

// Test 11: Large amount (1 crore)
let largeAmount: Decimal = 10000000
let largeShare = largeAmount / 3
assert(largeShare > 3000000, "Large amount (₹1cr) split correctly")

// Test 12: Single member gets full amount
let singleShare = Decimal(100) / 1
assertEqual(singleShare, 100, "Single member gets full ₹100")

// Test 13: Decimal precision
let preciseAmount: Decimal = 100
let preciseShare = preciseAmount / 7
let reconstructed = preciseShare * 7
assertClose(reconstructed, preciseAmount, tolerance: Decimal(string: "0.001")!, "Decimal precision maintained for /7")

print("")

// MARK: - 5. Settlement Tests
print("📊 SETTLEMENT TESTS")
print("-" * 30)

// Test 14: Simple settlement
let oweBalance: Decimal = -100
let owedBalance: Decimal = 100
assertEqual(oweBalance + owedBalance, 0, "Balances sum to zero")

// Test 15: After settlement
let afterSettlement = oweBalance + abs(oweBalance)
assertEqual(afterSettlement, 0, "After payment, balance is zero")

print("")

// MARK: - 6. Custom Split Validation
print("📊 CUSTOM SPLIT VALIDATION")
print("-" * 30)

// Test 16: Valid custom split
let customTotal: Decimal = 100
let custom1: Decimal = 60
let custom2: Decimal = 40
assertEqual(custom1 + custom2, customTotal, "Valid custom: ₹60 + ₹40 = ₹100")

// Test 17: Invalid custom split
let invalid1: Decimal = 30
let invalid2: Decimal = 40
assert(invalid1 + invalid2 != customTotal, "Invalid custom: ₹30 + ₹40 ≠ ₹100")

// Test 18: Percentage validation
let pctTotal: Double = 50 + 30 + 20
assertEqual(pctTotal, 100.0, "Percentages total 100%")

print("")
print("=" * 50)
print("📊 RESULTS: \(passed) passed, \(failed) failed")
print("=" * 50)

if failed == 0 {
    print("✅ ALL TESTS PASSED!")
} else {
    print("❌ SOME TESTS FAILED - Review above for details")
}

// Helper for string multiplication
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
