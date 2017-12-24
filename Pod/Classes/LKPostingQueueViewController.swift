//
//  LKPostingQueueTableViewController.swift
//  Pods
//
//  Created by Hiroshi Hashiguchi on 2015/05/31.
//
//

import UIKit
import LKQueue

open class LKPostingQueueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // models
    var selectedIndexPath: IndexPath!
    var postingQueueManager: LKPostingQueueManager!

    // tableview
    @IBOutlet weak var tableView: UITableView!
    
    // navigation bar
    var rightButtonItem: UIBarButtonItem!
    
    // tool bar
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var modeSegment: UISegmentedControl!
    @IBOutlet weak var toolbarHeightCOnstraint: NSLayoutConstraint!
    
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
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("ListTitle", bundle:postingQueueManagerBundle(), comment:"")
        
        tableView.register(UINib(nibName: "LKPostingQueueTableViewCell", bundle: postingQueueManagerBundle()), forCellReuseIdentifier: "LKPostingQueueTableViewCell")
        
        
        toolbarHeightCOnstraint.constant = postingQueueManager.toolbarHidden ? 0.0 : 44.0
        toolbarView.isHidden = postingQueueManager.toolbarHidden
        view.layoutIfNeeded()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(LKPostingQueueViewController.updated(_:)), name: NSNotification.Name(rawValue: kLKPostingQueueManagerNotificationUpdatedEntries), object: nil)
        nc.addObserver(self, selector: #selector(LKPostingQueueViewController.willPost(_:)), name: NSNotification.Name(rawValue: kLKPostingQueueManagerNotificationWillPostEntries), object: nil)
        nc.addObserver(self, selector: #selector(LKPostingQueueViewController.didPost(_:)), name: NSNotification.Name(rawValue: kLKPostingQueueManagerNotificationDidPostEntries), object: nil)
        nc.addObserver(self, selector: #selector(LKPostingQueueViewController.didAdd(_:)), name: NSNotification.Name(rawValue: kLKPostingQueueManagerNotificationDidAddEntries), object: nil)
        nc.addObserver(self, selector: #selector(LKPostingQueueViewController.failed(_:)), name: NSNotification.Name(rawValue: kLKPostingQueueManagerNotificationFailed), object: nil)
        nc.addObserver(self, selector: #selector(LKPostingQueueViewController.started(_:)), name: NSNotification.Name(rawValue: kLKPostingQueueManagerNotificationStarted), object: nil)
        nc.addObserver(self, selector: #selector(LKPostingQueueViewController.finished(_:)), name: NSNotification.Name(rawValue: kLKPostingQueueManagerNotificationFinished), object: nil)
        
        rightButtonItem = UIBarButtonItem(title: NSLocalizedString("Resume", bundle:postingQueueManagerBundle(), comment:""), style: UIBarButtonItemStyle.plain, target: self, action: #selector(LKPostingQueueViewController.resume(_:)))
        navigationItem.rightBarButtonItem = rightButtonItem
        
        modeSegment.setTitle(LKPostingQueueTransmitMode.auto.description(), forSegmentAt: 0)
        modeSegment.setTitle(LKPostingQueueTransmitMode.wifi.description(), forSegmentAt: 1)
        modeSegment.setTitle(LKPostingQueueTransmitMode.manual.description(), forSegmentAt: 2)
        modeSegment.selectedSegmentIndex = LKPostingQueueTransmitMode.defaultMode().rawValue
        
        emptyLabel.text = NSLocalizedString("Empty.Title", bundle:postingQueueManagerBundle(), comment: "")

        setupAppearance()
        updateUI()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        updateUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! LKPostingQueueLogViewController
        let indexPath = tableView.indexPath(for: sender as! LKPostingQueueTableViewCell)!
        controller.index = (indexPath as NSIndexPath).row
        controller.postingQueueManager = postingQueueManager
    }
    
    override open func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let indexPath = tableView.indexPath(for: sender as! LKPostingQueueTableViewCell)!
        return postingQueueManager.hasLogExisted((indexPath as NSIndexPath).row)
    }
    
    // MARK: - Table view data source
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postingQueueManager.count
    }
    
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LKPostingQueueTableViewCell", for: indexPath) as! LKPostingQueueTableViewCell
        
        let postingEntry = postingQueueManager.postingEntries[(indexPath as NSIndexPath).row]
        if let title = postingEntry.title {
            cell.label.text = title
        } else {
            cell.label.text = NSLocalizedString("Cell.NoTitle", bundle:postingQueueManagerBundle(), comment:"")
        }
        cell.detailLabel.text = postingEntry.subTitle
        if postingEntry.size == 0 {
            cell.sizelabel.text = ""
        } else {
            cell.sizelabel.text = ByteCountFormatter.string(fromByteCount: postingEntry.size, countStyle: .file)
        }
        if let backImagePath = postingEntry.backImagePath {
            if let image = UIImage(contentsOfFile: backImagePath) {
                cell.backImageView.image = image
            } else {
                cell.backImageView.image = nil
            }
        } else {
            cell.backImageView.image = nil
        }
        
        let queueEntry:LKQueueEntry = postingQueueManager.queue.entry(at: (indexPath as NSIndexPath).row)
        let proccessing = (queueEntry.state.rawValue == LKQueueEntryStateProcessing.rawValue)
        
        if (proccessing) {
            cell.accessoryType = UITableViewCellAccessoryType.none;
            cell.indicator.startAnimating()
        } else {
            if postingQueueManager.hasLogExisted((indexPath as NSIndexPath).row) {
                cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator;
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none;
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
    
    fileprivate func _removeEntry() {
        tableView.isEditing = false
        let queue = self.postingQueueManager.queue
        if let queueEntry = queue.entry(at: self.selectedIndexPath.row) {
            if let postingEntry = queueEntry.info as? LKPostingEntry {
                postingEntry.cleanup()
                queue.removeEntry(queueEntry)
                
                tableView.deleteRows(at: [self.selectedIndexPath], with: .left)
                self.selectedIndexPath = nil
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: kLKPostingQueueManagerNotificationUpdatedEntries), object: nil)
            }
        }
    }
    
    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            selectedIndexPath = indexPath
            
            if let delegate = postingQueueManager.delegate {
                delegate.handleRmoveEntry(view: view) {
                    self._removeEntry()
                }
            } else {
                let alertController = UIAlertController(title: NSLocalizedString("RemoveTitle", bundle:postingQueueManagerBundle(), comment:""), message: nil, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", bundle: postingQueueManagerBundle(), comment:""), style: .default, handler:nil))
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Remove", bundle:postingQueueManagerBundle(), comment:""), style: .default, handler: { (alertAction) -> Void in
                    self._removeEntry()
                }))
                
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !postingQueueManager.running
    }
    
    // MARK: - Table view delegate
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        performSegue(withIdentifier: "LKPostingQueueLogViewController", sender: cell)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return postingQueueManager.hasLogExisted((indexPath as NSIndexPath).row)
    }
    
    
    // MARK: - Privates (UI)
    func updateUI() {
        rightButtonItem.isEnabled = !postingQueueManager.running && postingQueueManager.count > 0
        emptyView.isHidden = postingQueueManager.count > 0
    }
    
    // MARK: - Privates (Notification)
    @objc func updated(_ notification:Notification) {
        tableView.reloadData()
        updateUI()
    }
    @objc func willPost(_ notification:Notification) {
        if let indexes = notification.object as? [Int] {
            let indexPaths = indexes.map({ (index) -> IndexPath in
                IndexPath(row: index, section: 0)
            })
            tableView.reloadRows(at: indexPaths, with: UITableViewRowAnimation.fade)
        }
    }
    @objc func didPost(_ notification:Notification) {
        if let indexes = notification.object as? [Int] {
            let indexPaths = indexes.map({ (index) -> IndexPath in
                IndexPath(row: index, section: 0)
            })
            tableView.deleteRows(at: indexPaths, with: UITableViewRowAnimation.automatic)
        }
        updateUI()
    }
    @objc func didAdd(_ notification:Notification) {
//        let indexPath = NSIndexPath(forRow: postingQueueManager.count-1, inSection: 0)
//        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        tableView.reloadData()
        updateUI()
    }

    @objc func failed(_ notification:Notification) {
        if let indexes = notification.object as? [Int] {
            let indexPaths = indexes.map({ (index) -> IndexPath in
                IndexPath(row: index, section: 0)
            })
            tableView.reloadRows(at: indexPaths, with: UITableViewRowAnimation.fade)
        }
        updateUI()
    }
    @objc func started(_ notification:Notification) {
        for cell in tableView.visibleCells {
            cell.setEditing(false, animated: true)
        }
        tableView.reloadData()
        updateUI()
    }
    @objc func finished(_ notification:Notification) {
        tableView.reloadData()
        updateUI()
    }
    
    // MARK: - Privates (Action)
    @objc func resume(_ sender:UIBarButtonItem) {
        postingQueueManager.resume(true)
        updateUI()
    }
    
    // MARK: - Actions
    @IBAction func onModeSegment(_ segment: UISegmentedControl) {
        if let mode = LKPostingQueueTransmitMode(rawValue: segment.selectedSegmentIndex) {
            mode.saveAsDefault()
        }
    }
    
}
