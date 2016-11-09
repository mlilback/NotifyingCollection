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

///a non-updateable object that defines identity by its name
class Part: Hashable, CustomStringConvertible {
	private(set) var name: String
	
	init(name: String) {
		self.name = name
	}
	
	var description: String { return "Part \(name)" }
	
	public var hashValue: Int { return ObjectIdentifier(self).hashValue }
	
	public static func ==(lhs: Part, rhs: Part) -> Bool {
		return lhs.name == rhs.name
	}
}

// an object that identifies itself by id, but the name is updateable
class Widget: Hashable, UpdateInPlace, CustomStringConvertible {
	let id: Int
	private(set) var name: String
	
	init(id: Int, name: String) {
		self.id = id
		self.name = name
	}
	
	var description: String { return "Widget \(id)" }
	
	func update(to: Widget) throws {
		guard id == to.id else { throw CollectionNotifierError.updateNotApplicable }
		name = to.name
	}
	
	public var hashValue: Int { return ObjectIdentifier(self).hashValue }
	
	public static func ==(lhs: Widget, rhs: Widget) -> Bool {
		return lhs.id == rhs.id
	}
}

class CollectionChangeSpec: QuickSpec {
	override func spec() {
		describe("a collection change") {
			
			context("widgets") {
				var notifier: CollectionNotifier<Widget>?
				var changes: [CollectionChange<Widget>]?
				var completed: Bool = false
				
				beforeEach {
					notifier = CollectionNotifier<Widget>()
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

				it("insert and remove widget") {
					expect(notifier!.values.count).to(equal(0))
					try! notifier!.append(Widget(id: 1, name: "foo"))
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
					expect(completed).to(beFalse())
					notifier = nil
					expect(changes?.count).to(equal(1))
					let aChange = changes!.first!
					expect(aChange.changeType).to(equal(ChangeType.done))
					expect(completed).to(beTrue()) //in addition to value of done, completed should also have been sent
				}
				
				it("update in place") {
					let updatedWidget = Widget(id: 3, name: "qux")
					try! notifier?.append(contentsOf: [Widget(id: 1, name: "foo"), Widget(id: 2, name: "bar"), Widget(id: 3, name: "baz")])
					expect(notifier?.values[2].name).to(equal("baz"))
					try! notifier?.update(at: 2, to: updatedWidget)
					expect(notifier?.values[2].name).to(equal(updatedWidget.name))
					expect{ try notifier?.update(at: 0, to: updatedWidget) }.to(throwError(CollectionNotifierError.updateNotApplicable))
				}
			}
		}
	}
}
