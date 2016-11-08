//
//  ArrayChange.swift
//
//  Copyright ©2016 Mark Lilback. This file is licensed under the ISC license.
//

import Foundation

/// - insert: an object was inserted
/// - remove: an object was removed
/// - update: 1+ properties have changed on an object
/// - reload: the entire collection should be reloaded as changes are too numerous (such as from sorting)
/// - nested: an object's property triggered changes
/// - done: no more changes are coming
public enum ChangeType {
	case insert, remove, update, reload, nested, done
}

/// Encapsulates a change in an array of type T objects.
public struct CollectionChange<T>: ChangeTypeNotification {
//	public static var refreshed: ArrayChange<T> { return ArrayChange() }
	
	public let changeType: ChangeType
	public let object: T?
	public let index: Int?
	public let nestedChanges: [AnyCollectionChange<T>]?
	
	/// initializer for a reload or done change. Only one may be true
	///
	/// - Parameters:
	///   - reload: should this be a .reload change
	///   - done: should this be a .done change
	public init(reload: Bool = false, done: Bool = false) {
		assert(reload || done)
		assert(!(reload && done))
		changeType = reload ? .reload : .done
		object = nil
		index = nil
		nestedChanges = nil
	}
	
	/// initializer for an .insert change
	///
	/// - Parameters:
	///   - obj: the object inserted
	///   - at: the index it was inserted at
	init(insert obj: T, at: Int) {
		changeType = .insert
		object = obj
		index = at
		nestedChanges = nil
	}
	
	/// initializer for a .remove change
	///
	/// - Parameters:
	///   - obj: the object that was removed
	///   - at: the index it was removed from
	init(remove obj: T, at: Int) {
		changeType = .remove
		object = obj
		index = at
		nestedChanges = nil
	}
	
	/// initializer for a .update change
	///
	/// - Parameter obj: the object that was updated
	init(update obj: T) {
		changeType = .update
		object = obj
		index = nil
		nestedChanges = nil
	}
	
	/// initializer for a nested change
	///
	/// - Parameters:
	///   - object: the object that had the nestedChanges
	///	  - nestedChanges: the nested CollectioChanges
	init(object: T, nestedChanges: [AnyCollectionChange<T>]) {
		changeType = .nested
		self.nestedChanges = nestedChanges
		self.object = object
		index = nil
	}
}

/// A protocol needed to allow for type erasure of nested changes
public protocol ChangeTypeNotification {
	associatedtype NotificationSource
	
	var changeType: ChangeType { get }
	var object: NotificationSource { get }
	var index: Int? { get }
}

/// type-erased CollectionChange
public struct AnyCollectionChange<T>: ChangeTypeNotification
{
	public typealias NotificationSource = CollectionChange<T>
	private let _source: NotificationSource

	public var changeType: ChangeType { return _source.changeType }
	public var object: NotificationSource { return _source }
	public var index: Int? { return _source.index }
}

