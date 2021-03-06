//
//  FeedListViewController.swift
//  Evergreen
//
//  Created by Brent Simmons on 11/1/17.
//  Copyright © 2017 Ranchero Software. All rights reserved.
//

import Cocoa
import RSTree
import RSCore

final class FeedListViewController: NSViewController {

	@IBOutlet var outlineView: NSOutlineView!
	private var sidebarCellAppearance: SidebarCellAppearance!
	private let treeControllerDelegate = FeedListTreeControllerDelegate()
	lazy var treeController: TreeController = {
		TreeController(delegate: treeControllerDelegate)
	}()

	// MARK: NSViewController

	override func viewDidLoad() {

		sidebarCellAppearance = SidebarCellAppearance(theme: appDelegate.currentTheme, fontSize: AppDefaults.shared.sidebarFontSize)
		NotificationCenter.default.addObserver(self, selector: #selector(faviconDidBecomeAvailable(_:)), name: .FaviconDidBecomeAvailable, object: nil)
	}

	// MARK: - Notifications

	@objc func faviconDidBecomeAvailable(_ note: Notification) {

		configureAvailableCells()
	}
}

// MARK: - NSOutlineViewDataSource

extension FeedListViewController: NSOutlineViewDataSource {

	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		
		return nodeForItem(item as AnyObject?).numberOfChildNodes
	}

	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {

		return nodeForItem(item as AnyObject?).childNodes![index]
	}

	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {

		return nodeForItem(item as AnyObject?).canHaveChildNodes
	}

	private func nodeForItem(_ item: AnyObject?) -> Node {

		if item == nil {
			return treeController.rootNode
		}
		return item as! Node
	}
}

// MARK: - NSOutlineViewDelegate

extension FeedListViewController: NSOutlineViewDelegate {

	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {

		let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FeedListCell"), owner: self) as! SidebarCell

		let node = item as! Node
		configure(cell, node)

		return cell
	}

	func outlineViewSelectionDidChange(_ notification: Notification) {

//		// TODO: support multiple selection
//
//		let selectedRow = self.outlineView.selectedRow
//
//		if selectedRow < 0 || selectedRow == NSNotFound {
//			postSidebarSelectionDidChangeNotification(nil)
//			return
//		}
//
//		if let selectedNode = self.outlineView.item(atRow: selectedRow) as? Node {
//			postSidebarSelectionDidChangeNotification([selectedNode.representedObject])
//		}
	}

	private func configure(_ cell: SidebarCell, _ node: Node) {

		cell.cellAppearance = sidebarCellAppearance
		cell.objectValue = node
		cell.name = nameFor(node)
		cell.image = imageFor(node)
		cell.shouldShowImage = node.representedObject is FeedListFeed
	}

	func imageFor(_ node: Node) -> NSImage? {

		guard let feed = node.representedObject as? FeedListFeed else {
			return nil
		}
		return appDelegate.faviconDownloader.favicon(withHomePageURL: feed.homePageURL)
	}

	func nameFor(_ node: Node) -> String {

		if let displayNameProvider = node.representedObject as? DisplayNameProvider {
			return displayNameProvider.nameForDisplay
		}
		return ""
	}
}

private extension FeedListViewController {

	func nodeForRow(_ row: Int) -> Node? {

		if row < 0 || row >= outlineView.numberOfRows {
			return nil
		}

		if let node = outlineView.item(atRow: row) as? Node {
			return node
		}
		return nil
	}

	func cellForRowView(_ rowView: NSTableRowView) -> SidebarCell? {

		return rowView.view(atColumn: 0) as? SidebarCell
	}

	func configureAvailableCells() {

		outlineView.enumerateAvailableRowViews { (rowView: NSTableRowView, row: Int) -> Void in

			guard let cell = cellForRowView(rowView), let node = nodeForRow(row) else {
				return
			}
			configure(cell, node)
		}
	}
}
