//
//  CollectionChangeSpec.swift
//
//  Copyright ©2016 Mark Lilback. This file is licensed under the ISC license.
//

import Foundation
import Quick
import Nimble
import ReactiveSwift
@testable import NotifyingCollection

class TestWidget: Hashable {
	let name: String
	
	init(name: String) {
		self.name = name
	}
	
	public var hashValue: Int { return ObjectIdentifier(self).hashValue }
	
	public static func ==(lhs: TestWidget, rhs: TestWidget) -> Bool {
		return lhs.name == rhs.name
	}
}

class CollectionChangeSpec: QuickSpec {
	override func spec() {
		describe("a collection change") {
			var notifier: CollectionNotifier<TestWidget>?
			var changes: [CollectionChange<TestWidget>]?
			var completed: Bool = false
			
			beforeEach {
				notifier = CollectionNotifier<TestWidget>()
				changes = nil
				completed = false
				notifier!.changeSignal.observe() { event in
					switch event {
					case .value(let val):
						changes = val
					case .completed:
						completed = true
					default:
						break
					}
				}
			}
			
			
			it("insert and remove object") {
				expect(notifier!.values.count).to(equal(0))
				try! notifier!.append(TestWidget(name: "foo"))
				expect(changes?.count).to(equal(1))
				var aChange = changes!.first!
				expect(aChange.changeType).to(equal(ChangeType.insert))
				expect(aChange.object!.name).to(equal("foo"))
				try! notifier!.remove(at: 0)
				aChange = changes!.first!
				expect(aChange.changeType).to(equal(ChangeType.remove))
				expect(aChange.object!.name).to(equal("foo"))
			}
			
			it("done event sent") {
				notifier = nil
				expect(changes?.count).to(equal(1))
				let aChange = changes!.first!
				expect(aChange.changeType).to(equal(ChangeType.done))
				expect(completed).to(beTrue())
			}
		}
	}
}
