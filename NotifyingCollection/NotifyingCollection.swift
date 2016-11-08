//
//  NotifyingCollection.swift
//
//  Copyright ©2016 Mark Lilback. This file is licensed under the ISC license.
//

import Foundation
import ReactiveSwift
import Result

/// Errors thrown by the CollectionNotifier class
public enum CollectionNotifierError: Error {
	case indexOutOfBounds
	case noSuchElement
	case duplicateElement
}

/// A protocol for objects that can be updated in place and keep the same object identity. Their equality should not be based on their content (or use ObjectIdentifier).
public protocol UpdateInPlace {
	associatedtype UElement
	/// update the object to match the appropriate properties of parameter
	/// - Parameter to: the object to update prperties from
	func update(to: UElement) throws
}

/// Elements in an ArrayWrapper must be a class and Equatable
public typealias ArrayWrapperElement = Hashable & AnyObject

/// Maintains an array of a class, sending ArrayChanges via the changeSignal property.
/// Duplicate elements are not allowed.
/// Normally this should be an internal/private property with the values and changeSignal
/// properties exposed via public computed properties
///
/// to easily implement Hashable, use the following:
///
/// ```swift
/// var hashValue: Int { 
///		return ObjectIdentifier(self).hashValue
/// }
///
/// static func == (lhs: MyClass, rhs: MyClass) -> Bool {
///     return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
/// }
/// ```
///
public final class CollectionNotifier<Element: ArrayWrapperElement>: Collection, ExpressibleByArrayLiteral
{
	public typealias Change = CollectionChange<Element>
	public var values: [Element] { return _array }
	public private(set) var changeSignal: Signal<[Change], NoError>
	
	fileprivate var changeObserver: Observer<[Change], NoError>
	fileprivate var _array: [Element] = []
	private var _pendingChanges: [Change]?
	
	public var count: Int { return _array.count }
	
	public init() {
		let (signal, observer) = Signal<[Change], NoError>.pipe()
		changeSignal = signal
		changeObserver = observer
	}
	
	/// initialize with an array literal
	///
	/// - Parameter elements: elements to add
	public convenience init(arrayLiteral elements: Element...) {
		self.init()
		//force because only throws if there is auplicate element
		try! append(contentsOf: elements)
	}

	deinit {
		changeObserver.send(value: [Change(done: true)])
		changeObserver.sendCompleted()
	}
	
	/// true if stopGroupingChanges() was called and not yet followed by stopGroupingChanges() or cancelGroupedChanges()
	public var isGroupingChanges: Bool { return _pendingChanges == nil }
	
	/// Will cache all changes until stopGroupingChanges is called
	public func startGroupingChanges() {
		assert(_pendingChanges == nil)
		_pendingChanges = []
	}
	
	/// Stops caching changes and immediately sends any cached changes in one signal value
	public func stopGroupingChanges() {
		assert(_pendingChanges != nil)
		changeObserver.send(value: _pendingChanges!)
		_pendingChanges = nil
	}
	
	/// Clears all pending changes
	public func cancelGroupedChanges() {
		_pendingChanges = nil
	}
	
	/// Append a single element sending a change notification
	///
	/// - Parameter element: element to add
	/// - Throws: .duplicateElement
	public func append(_ element: Element) throws {
		try append(contentsOf: [element])
	}
	
	/// Appends elements of collection to values array, sending change notifications
	///
	/// - Parameter newElements: elemnts to append to values array
	/// - Throws: .duplicateElement
	public func append<C: Collection>(contentsOf newElements: C) throws where C.Iterator.Element == Element
	{
		//make sure _array doesn't already contain any of newElements's objects
		let newSet = Set<Element>(newElements)
		guard newSet.intersection(_array).count == 0 else {
			throw CollectionNotifierError.duplicateElement
		}
		//iterate newElements adding each value and creating a change notification to send
		var changes: [CollectionChange<Element>] = []
		for val in newElements {
			_array.append(val)
			changes.append(CollectionChange(insert: val, at: _array.count - 1))
		}
		sendChanges(changes)
	}
	
	/// inserts value into values array
	///
	/// - Parameters:
	///   - value: the value to insert
	///   - index: the index to insert it at
	/// - Throws: .indexOutOfBounds, duplicateElement
	public func insert(value: Element, at index: Int) throws {
		guard index >= 0 && index <= _array.count else {
			throw CollectionNotifierError.indexOutOfBounds
		}
		guard !_array.contains(value) else {
			throw CollectionNotifierError.duplicateElement
		}
		_array.insert(value, at: index)
		sendChanges([CollectionChange(insert: value, at: index)])
	}
	
	/// Removes value, sending a change notification
	///
	/// - Parameter value: the value to remove
	/// - Throws: .noSuchElement
	public func remove(_ value: Element) throws {
		guard let idx = _array.index(of: value) else {
			throw CollectionNotifierError.noSuchElement
		}
		_array.remove(at: idx)
		sendChanges([CollectionChange(remove: value, at: idx)])
	}
	
	/// Removes value at index, sending a change notification
	///
	/// - Parameter at: the index to remove
	/// - Throws: .indexOutOfBounds
	public func remove(at index: Int) throws {
		guard index >= 0 && index <= _array.count else {
			throw CollectionNotifierError.indexOutOfBounds
		}
		let toRemove = _array[index]
		_array.remove(at: index)
		sendChanges([CollectionChange(remove: toRemove, at: index)])
	}
	
	/// Removes all values from the values array, sending change notifications
	public func removeAll() {
		_array.removeAll()
		sendChanges([CollectionChange<Element>()])
	}
	
	/// used internally to send changes, grouping if configured to do so
	fileprivate func sendChanges(_ changes: [Change]) {
		guard _pendingChanges == nil else {
			_pendingChanges?.append(contentsOf: changes)
			return
		}
		changeObserver.send(value: changes)
	}

	// MARK: - Collection implementation

	public var startIndex: Int { return values.startIndex }
	public var endIndex: Int { return values.endIndex }
	public subscript(index: Int) -> Element {
		return values[index]
	}
	public func index(after i: Int) -> Int {
		return values.index(after: i)
	}
}

public extension CollectionNotifier where Element: UpdateInPlace {
	/// If the Element class conforms to UpdateInPlace, this method
	/// will call update() on the element and signal an appropriate change signal
	/// - Parameter at: the index of the object to update
	/// - Parameter to: the object the elment should update itself to match
	/// - Throws: any exception thrown by the Element's update() method
	public func update(at index: Int, to object: Element.UElement) throws {
		let theValue = values[index]
		try theValue.update(to: object)
		sendChanges([CollectionChange(update: theValue)])
	}
}
