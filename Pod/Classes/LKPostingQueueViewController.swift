//
//  LKPostingQueueTableViewController.swift
//  Pods
//
//  Created by Hiroshi Hashiguchi on 2015/05/31.
//
//

import UIKit
import LKQueue

public class LKPostingQueueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // models
    var selectedIndexPath: NSIndexPath!
    var postingQueueManager: LKPostingQueueManager!

    // tableview
    @IBOutlet weak var tableView: UITableView!
    
    // navigation bar
    var rightButtonItem: UIBarButtonItem!
    
    // tool bar
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var modeSegment: UISegmentedControl!
    
    // empty view
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyLabel: UILabel!
    

    func setupAppearance() {
        let appearance = postingQueueManager.appearance
        
        if let color = appearance.backColor {
            view.backgroundColor = color
        }
        if let color = appearance.tableColor {
            tableView.backgroundColor = color
        }
        if let color = appearance.tableSeparatorColor {
            tableView.separatorColor = color
        }
        
        if let color = appearance.titleColor {
            LKPostingQueueTableViewCell.appearance().tintColor = color
            emptyLabel.textColor = color
        }
        
        if let color = appearance.barColor {
            toolbarView.backgroundColor = color
        }
        
        if let color = appearance.textColor {
            modeSegment.tintColor = color;
        }

    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("ListTitle", bundle:postingQueueManagerBundle(), comment:"")
        
        tableView.registerNib(UINib(nibName: "LKPostingQueueTableViewCell", bundle: postingQueueManagerBundle()), forCellReuseIdentifier: "LKPostingQueueTableViewCell")
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "updated:", name: kLKPostingQueueManagerNotificationUpdatedEntries, object: nil)
        nc.addObserver(self, selector: "willPost:", name: kLKPostingQueueManagerNotificationWillPostEntry, object: nil)
        nc.addObserver(self, selector: "didPost:", name: kLKPostingQueueManagerNotificationDidPostEntry, object: nil)
        nc.addObserver(self, selector: "didAdd:", name: kLKPostingQueueManagerNotificationDidAddEntry, object: nil)
        nc.addObserver(self, selector: "failed:", name: kLKPostingQueueManagerNotificationFailed, object: nil)
        nc.addObserver(self, selector: "started:", name: kLKPostingQueueManagerNotificationStarted, object: nil)
        nc.addObserver(self, selector: "finished:", name: kLKPostingQueueManagerNotificationFinished, object: nil)
        
        rightButtonItem = UIBarButtonItem(title: NSLocalizedString("Resume", bundle:postingQueueManagerBundle(), comment:""), style: UIBarButtonItemStyle.Plain, target: self, action: "resume:")
        navigationItem.rightBarButtonItem = rightButtonItem
        
        modeSegment.setTitle(LKPostingQueueTransmitMode.Auto.description(), forSegmentAtIndex: 0)
        modeSegment.setTitle(LKPostingQueueTransmitMode.Wifi.description(), forSegmentAtIndex: 1)
        modeSegment.setTitle(LKPostingQueueTransmitMode.Manual.description(), forSegmentAtIndex: 2)
        modeSegment.selectedSegmentIndex = LKPostingQueueTransmitMode.defaultMode().rawValue
        
        emptyLabel.text = NSLocalizedString("Empty.Title", bundle:postingQueueManagerBundle(), comment: "")

        setupAppearance()
        updateUI()
    }
    
    override public func viewWillAppear(animated: Bool) {
        updateUI()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let controller = segue.destinationViewController as! LKPostingQueueLogViewController
        let indexPath = tableView.indexPathForCell(sender as! LKPostingQueueTableViewCell)!
        controller.index = indexPath.row
        controller.postingQueueManager = postingQueueManager
    }
    
    override public func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        let indexPath = tableView.indexPathForCell(sender as! LKPostingQueueTableViewCell)!
        return postingQueueManager.hasLogExisted(indexPath.row)
    }
    
    // MARK: - Table view data source
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postingQueueManager.count
    }
    
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LKPostingQueueTableViewCell", forIndexPath: indexPath) as! LKPostingQueueTableViewCell
        
        let postingEntry = postingQueueManager.postingEntries[indexPath.row]
        if let title = postingEntry.title {
            cell.label.text = title
        } else {
            cell.label.text = NSLocalizedString("Cell.NoTitle", bundle:postingQueueManagerBundle(), comment:"")
        }
        cell.detailLabel.text = postingEntry.subTitle
        if postingEntry.size == 0 {
            cell.sizelabel.text = ""
        } else {
            cell.sizelabel.text = NSByteCountFormatter.stringFromByteCount(postingEntry.size, countStyle: .File)
        }
        if let imagePath = postingEntry.imagePath {
            if let image = UIImage(contentsOfFile: imagePath) {
                cell.backImageView.image = image
            } else {
                cell.backImageView.image = nil
            }
        } else {
            cell.backImageView.image = nil
        }
        
        let queueEntry:LKQueueEntry = postingQueueManager.queue.entryAtIndex(indexPath.row)
        let proccessing = (queueEntry.state.rawValue == LKQueueEntryStateProcessing.rawValue)
        
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
            cell.indicator.color = color
        }
        if let color = appearance.cellDetailTextColor {
            cell.detailLabel?.textColor = color
        }

        if let color = appearance.selectedCellColor {
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView!.backgroundColor = color
        }
        if let color = appearance.cellColor {
            cell.backgroundColor = color
        }
        
        return cell
    }
    
    public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            selectedIndexPath = indexPath
            
            let alertController = UIAlertController(title: NSLocalizedString("RemoveTitle", bundle:postingQueueManagerBundle(), comment:""), message: nil, preferredStyle: .Alert)

            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", bundle: postingQueueManagerBundle(), comment:""), style: .Default, handler:nil))
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Remove", bundle:postingQueueManagerBundle(), comment:""), style: .Default, handler: { (alertAction) -> Void in
                tableView.editing = false
                let queue = self.postingQueueManager.queue
                if let queueEntry = queue.entryAtIndex(self.selectedIndexPath.row) {
                    if let postingEntry = queueEntry.info as? LKPostingEntry {
                        postingEntry.cleanup()
                        queue.removeEntry(queueEntry)
                        
                        tableView.deleteRowsAtIndexPaths([self.selectedIndexPath], withRowAnimation: .Left)
                        self.selectedIndexPath = nil
                        
                        NSNotificationCenter.defaultCenter().postNotificationName(kLKPostingQueueManagerNotificationUpdatedEntries, object: nil)
                    }
                }
            }))
            
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return !postingQueueManager.running
    }
    
    // MARK: - Table view delegate
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        performSegueWithIdentifier("LKPostingQueueLogViewController", sender: cell)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    public func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return postingQueueManager.hasLogExisted(indexPath.row)
    }
    
    
    // MARK: - Privates (UI)
    func updateUI() {
        rightButtonItem.enabled = !postingQueueManager.running && postingQueueManager.count > 0
        emptyView.hidden = postingQueueManager.count > 0
    }
    
    // MARK: - Privates (Notification)
    func updated(notification:NSNotification) {
        tableView.reloadData()
        updateUI()
    }
    func willPost(notification:NSNotification) {
        if let index = notification.object as? Int {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    func didPost(notification:NSNotification) {
        if let index = notification.object as? Int {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Right)
        }
        updateUI()
    }
    func didAdd(notification:NSNotification) {
        let indexPath = NSIndexPath(forRow: postingQueueManager.count-1, inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        updateUI()
    }
    func failed(notification:NSNotification) {
        if let index = notification.object as? Int {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
        updateUI()
    }
    func started(notification:NSNotification) {
        for cell in tableView.visibleCells {
            cell.setEditing(false, animated: true)
        }
        tableView.reloadData()
        updateUI()
    }
    func finished(notification:NSNotification) {
        tableView.reloadData()
        updateUI()
    }
    
    // MARK: - Privates (Action)
    func resume(sender:UIBarButtonItem) {
        postingQueueManager.start(true)
        updateUI()
    }
    
    // MARK: - Actions
    @IBAction func onModeSegment(segment: UISegmentedControl) {
        if let mode = LKPostingQueueTransmitMode(rawValue: segment.selectedSegmentIndex) {
            mode.saveAsDefault()
        }
    }
    
}
