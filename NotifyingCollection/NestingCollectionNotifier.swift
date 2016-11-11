//
//  NestingCollectionNotifier.swift
//
//  Copyright ©2016 Mark Lilback. This file is licensed under the ISC license.
//

import Foundation
import ReactiveSwift
import Result

final class NestedInfo<Element: ArrayWrapperElement> {
	
	let observe: (Element) -> Disposable?
	var disposables: [Element: Disposable] = [Element: Disposable]()
	
	init(observer: @escaping (Element) -> Disposable?) {
		self.observe = observer
	}
	
	func startObserving(_ element: Element) {
		if let disp = observe(element) {
			disposables[element] = disp
		}
	}
	
	func stopObserving(_ element: Element) {
		disposables.removeValue(forKey: element)
	}
}

/// Subclass of CollectionNotifier that allows observing changes of elements
public final class NestingCollectionNotifier<Element: ArrayWrapperElement>: CollectionNotifier<Element>
{
	public typealias ElementObserver = (Element) -> Disposable?
	var _observersInfo = [String: NestedInfo<Element>]()

	/// Sets a closure to call when an Element is added to allow for listening to nested changes
	///
	/// - Parameters:
	///   - identifier: an identifier to allow for later removal of this observer
	///   - observer: a closure that takes an Element and returns a disposable
	public func observe(identifier: String, observer: @escaping ElementObserver)
	{
		let info = NestedInfo<Element>(observer: observer)
		_observersInfo[identifier] = info
		//observe all current Elements
		_array.forEach { info.startObserving($0) }
	}

	/// Removes an observer added via observe()
	///
	/// - Parameter identifier: the identifier of the observer to remove
	public func removeObserver(identifier: String) {
		_observersInfo.removeValue(forKey: identifier)
	}

	/// overridden to tell observers to observe this element
	override func insertInArray(element: Element, index: Int) {
		super.insertInArray(element: element, index: index)
		_observersInfo.forEach { (k, v) in v.startObserving(element) }
	}
	
	/// overridden to tell observers to stop observing element at index
	override func removeFromArray(index: Int) {
		if let element = valueAtIndex(index) {
			_observersInfo.forEach { (k, v) in v.stopObserving(element) }
		}
		super.removeFromArray(index: index)
	}
	
	//also remove observer info
	override public func removeAll() {
		super.removeAll()
		_observersInfo.removeAll()
	}
}
