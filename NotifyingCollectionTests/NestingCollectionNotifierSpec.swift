//
//  NestingCollectionNotifierSpec.swift
//
//  Copyright ©2016 Mark Lilback. This file is licensed under the ISC license.
//

import Foundation
import Quick
import Nimble
import ReactiveSwift
@testable import NotifyingCollection

///a non-updateable object that defines identity by its name
class NPart: Hashable, CustomStringConvertible {
	private(set) var name: String
	
	init(name: String) {
		self.name = name
	}
	
	var description: String { return "Part \(name)" }
	
	public var hashValue: Int { return ObjectIdentifier(self).hashValue }
	
	public static func ==(lhs: NPart, rhs: NPart) -> Bool {
		return lhs.name == rhs.name
	}
}

// an object that identifies itself by id, but the name is updateable
class NWidget: Hashable, UpdateInPlace, CustomStringConvertible {
	let id: Int
	private(set) var name: String
	let _parts: NestingCollectionNotifier<NPart>
	
	init(id: Int, name: String, parts: [NPart]) {
		self.id = id
		self.name = name
		_parts = NestingCollectionNotifier<NPart>(elements: parts)
	}
	
	var description: String { return "Widget \(id)" }
	
	func update(to: NWidget) throws {
		guard id == to.id else { throw CollectionNotifierError.updateNotApplicable }
		name = to.name
	}
	
	public var hashValue: Int { return ObjectIdentifier(self).hashValue }
	
	public static func ==(lhs: NWidget, rhs: NWidget) -> Bool {
		return lhs.id == rhs.id
	}
}

class NestingCollectionNotifierSpec: QuickSpec {
	var lastChanges: [CollectionChange<NPart>]?
	
	override func spec() {
		describe("nested change") {
			let tirePart = NPart(name: "Tire")
			let axelPart = NPart(name: "Axel")
			let w1 = NWidget(id: 1, name: "WheelWidget", parts: [tirePart, axelPart])
			let collection = NestingCollectionNotifier<NWidget>(elements: [w1])
			collection.observe(identifier: "parts", observer: observeWidgetParts)
			try! w1._parts.append(NPart(name: "Hubcap"))
			collection.changeSignal.observe { changes in
				print("got changes: \(changes)")
			}
			expect(self.lastChanges?.count).to(equal(1))
			expect(self.lastChanges?.first?.changeType).to(equal(ChangeType.insert))
			expect(self.lastChanges?.first?.object?.name).to(equal("Hubcap"))
		}
	}
	
	func observeWidgetParts(widget: NWidget) -> Disposable? {
		return widget._parts.changeSignal.observe { [weak self] event in
			switch event {
				case .value(let changes):
					self?.partChanged(widget: widget, changes: changes)
				default:
					break
			}
		}
	}
	
	func partChanged(widget: NWidget, changes: [CollectionChange<NPart>])
	{
		lastChanges = changes
		print("changes: \(changes)")
	}
}
