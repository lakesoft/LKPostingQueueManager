//
//  LKPostingQueueTableViewController.swift
//  Pods
//
//  Created by Hiroshi Hashiguchi on 2015/05/31.
//
//

import UIKit

public class LKPostingQueueTableViewController: UITableViewController, UIActionSheetDelegate{
    
    var rightButtonItem: UIBarButtonItem!
    var selectedIndexPath: NSIndexPath!
    var postingQueueManager: LKPostingQueueManager!
    
    func setupAppearance() {
        let appearance = postingQueueManager.appearance
        
        if let color = appearance.backColor {
            view.backgroundColor = color
        }
        if let color = appearance.tableColor {
            tableView.backgroundColor = appearance.tableColor
        }
        if let color = appearance.tableSeparatorColor {
            tableView.separatorColor = appearance.tableSeparatorColor
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("ListTitle", bundle:postingQueueManagerBundle(), comment:"")
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "updated:", name: kLKPostingQueueManagerNotificationUpdated, object: nil)
        nc.addObserver(self, selector: "posted:", name: kLKPostingQueueManagerNotificationPostedEntry, object: nil)
        nc.addObserver(self, selector: "added:", name: kLKPostingQueueManagerNotificationAddedEntry, object: nil)
        nc.addObserver(self, selector: "finished:", name: kLKPostingQueueManagerNotificationFinished, object: nil)
        
        rightButtonItem = UIBarButtonItem(title: NSLocalizedString("Resume", bundle:postingQueueManagerBundle(), comment:""), style: UIBarButtonItemStyle.Plain, target: self, action: "resume:")
        navigationItem.rightBarButtonItem = rightButtonItem
        
        setupAppearance()
        updateUI()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let controller = segue.destinationViewController as! LKPostingQueueLogViewController
        let indexPath = tableView.indexPathForCell(sender as! LKPostingQueueTableViewCell)!
        controller.index = indexPath.row
    }
    
    override public func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        let indexPath = tableView.indexPathForCell(sender as! LKPostingQueueTableViewCell)!
        return postingQueueManager.hasLogExisted(indexPath.row)
    }
    
    // MARK: - Table view data source
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postingQueueManager.count
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LKPostingQueueTableViewCell", forIndexPath: indexPath) as! LKPostingQueueTableViewCell
        
        let postingEntry = postingQueueManager.postingEntries[indexPath.row]
        cell.label.text = postingEntry.title
        if postingEntry.size == 0 {
            cell.sizelabel.text = ""
        } else {
            cell.sizelabel.text = NSByteCountFormatter.stringFromByteCount(postingEntry.size, countStyle: .File)
        }
        
        let proccessing = indexPath.row == 0 && postingQueueManager.running
        
        if (proccessing) {
            cell.accessoryType = UITableViewCellAccessoryType.None;
            cell.indicator.startAnimating()
        } else {
            if postingQueueManager.hasLogExisted(indexPath.row) {
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator;
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None;
            }
            cell.indicator.stopAnimating()
        }
        
        let appearance = postingQueueManager.appearance
        if let color = appearance.cellTextColor {
            cell.label?.textColor = color
            cell.sizelabel?.textColor = color
            cell.label?.textColor = color
            cell.indicator.tintColor = color
        }
        if let color = appearance.cellColor {
            cell.backgroundColor = color
        }
        
        return cell
    }
    
    override public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            selectedIndexPath = indexPath
            let actionSheet = UIActionSheet(title: NSLocalizedString("RemoveTitle", bundle:postingQueueManagerBundle(), comment:""), delegate: self, cancelButtonTitle: NSLocalizedString("Cancel", bundle:postingQueueManagerBundle(), comment:""), destructiveButtonTitle: NSLocalizedString("Remove", bundle:postingQueueManagerBundle(), comment:""))
            actionSheet.showInView(view)
        }
    }
    
    override public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return !postingQueueManager.running
    }
    
    // MARK: - Table view delegate
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    
    // MARK: - Privates (UI)
    func updateUI() {
        rightButtonItem.enabled = !postingQueueManager.running && postingQueueManager.count > 0
    }
    
    // MARK: - Privates (Notification)
    func updated(notification:NSNotification) {
        tableView.reloadData()
    }
    func posted(notification:NSNotification) {
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Right)
        if postingQueueManager.count > 0 {
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
        updateUI()
    }
    func added(notification:NSNotification) {
        let indexPath = NSIndexPath(forRow: postingQueueManager.count-1, inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        updateUI()
    }
    func finished(notification:NSNotification) {
        updateUI()
    }
    
    // MARK: - Privates (Action)
    func resume(sender:UIBarButtonItem) {
        postingQueueManager.start(true)
        updateUI()
    }
    
    // MARK: - UIActionSeetDelete
    public func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        tableView.editing = false
        if actionSheet.cancelButtonIndex != buttonIndex {
            let queue = postingQueueManager.queue
            if let queueEntry = queue.entryAtIndex(selectedIndexPath.row) {
                if let postingEntry = queueEntry.info as? LKPostingEntry {
                    postingEntry.cleanup()
                    queue.removeEntry(queueEntry)
                    
                    tableView.deleteRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Left)
                    selectedIndexPath = nil
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(kLKPostingQueueManagerNotificationUpdated, object: nil)
                }
            }
        }
    }
}
