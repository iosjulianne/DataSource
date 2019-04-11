//
//  MutableDataSource.swift
//  DataSource
//
//  Created by Vadim Yelagin on 04/06/15.
//  Copyright (c) 2015 Fueled. All rights reserved.
//

import Foundation
import Ry

/// `DataSource` implementation that has one section of items of type T.
///
/// The array of items can be modified by calling methods that perform
/// individual changes and instantly make the dataSource emit
/// a corresponding dataChange.
public final class MutableDataSource<T>: DataSource {

	private let changesPipe = SignalPipe<DataChange>()
	public var changes: Signal<DataChange> {
		return changesPipe.signal
	}

	private let _items: Property<[T]>

	public var items: ReadOnlyProperty<[T]> {
		return _items.readOnly
	}

	public let supplementaryItems: [String: Any]

	public init(_ items: [T] = [], supplementaryItems: [String: Any] = [:]) {
		_items = Property(initialValue: items)
		self.supplementaryItems = supplementaryItems
	}

	public let numberOfSections = 1

	public func numberOfItemsInSection(_ section: Int) -> Int {
		return _items.value.count
	}

	public func supplementaryItemOfKind(_ kind: String, inSection section: Int) -> Any? {
		return supplementaryItems[kind]
	}

	public func item(at indexPath: IndexPath) -> Any {
		return _items.value[indexPath.item]
	}

	public func leafDataSource(at indexPath: IndexPath) -> (DataSource, IndexPath) {
		return (self, indexPath)
	}

	/// Inserts a given item at a given index
	/// and emits `DataChangeInsertItems`.
	public func insertItem(_ item: T, at index: Int) {
		insertItems([item], at: index)
	}

	/// Inserts items at a given index
	/// and emits `DataChangeInsertItems`.
	public func insertItems(_ items: [T], at index: Int) {
		_items.value.insert(contentsOf: items, at: index)
		let change = DataChangeInsertItems(items.indices.map { z(index + $0) })
		changesPipe.send(change)
	}

	/// Deletes an item at a given index
	/// and emits `DataChangeDeleteItems`.
	public func deleteItem(at index: Int) {
		deleteItems(in: Range(index...index))
	}

	/// Deletes items in a given range
	/// and emits `DataChangeDeleteItems`.
	public func deleteItems(in range: Range<Int>) {
		_items.value.removeSubrange(range)
		let change = DataChangeDeleteItems(range.map(z))
		changesPipe.send(change)
	}

	/// Replaces an item at a given index with another item
	/// and emits `DataChangeReloadItems`.
	public func replaceItem(at index: Int, with item: T) {
		_items.value[index] = item
		let change = DataChangeReloadItems(z(index))
		changesPipe.send(change)
	}

	/// Moves an item at a given index to another index
	/// and emits `DataChangeMoveItem`.
	public func moveItem(at oldIndex: Int, to newIndex: Int) {
		let item = _items.value.remove(at: oldIndex)
		_items.value.insert(item, at: newIndex)
		let change = DataChangeMoveItem(from: z(oldIndex), to: z(newIndex))
		changesPipe.send(change)
	}

	/// Replaces all items with a given array of items
	/// and emits `DataChangeReloadSections`.
	public func replaceItems(with items: [T]) {
		_items.value = items
		let change = DataChangeReloadSections([0])
		changesPipe.send(change)
	}

}

private func z(_ index: Int) -> IndexPath {
	return IndexPath(item: index, section: 0)
}
