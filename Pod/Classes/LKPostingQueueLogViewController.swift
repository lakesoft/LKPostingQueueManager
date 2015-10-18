//
//  PostingQueueLogViewController.swift
//  Pods
//
//  Created by Hiroshi Hashiguchi on 2015/05/31.
//
//

import UIKit
import MessageUI

extension String {
    func stringByAppendingPathComponent(path: String) -> String {
        return (self as NSString).stringByAppendingPathComponent(path)
    }
    var pathExtension: String {
        return (self as NSString).pathExtension
    }
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
}

class LKPostingQueueLogViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var mailButtonItem: UIBarButtonItem!
    @IBOutlet weak var copyLogButtonItem: UIBarButtonItem!
    
    var postingQueueManager: LKPostingQueueManager!
    
    var index: Int = 0
    
    func setupAppearance() {
        let appearance = postingQueueManager.appearance
        if let color = appearance.backColor {
            view.backgroundColor = color
        }
        if let color = appearance.barColor {
            toolbar.tintColor = color
        }
        if let color = appearance.buttonColor {
            mailButtonItem.tintColor = color
            copyLogButtonItem.tintColor = color
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        textView.text = postingQueueManager.log(index)
        title = NSLocalizedString("LogTitle", bundle:postingQueueManagerBundle(), comment: "")
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "started:", name: kLKPostingQueueManagerNotificationStarted, object: nil)

    }
    
    func started(notification:NSNotification) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Privates
    func mimeTypeForFilePath(filePath: String) -> String {
        switch filePath.pathExtension.lowercaseString {
        case "gif":
            return "image/gif"
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "mov":
            return "video/quicktime"
        default:
            return "application/octet-stream"
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onSendMail(sender: AnyObject) {
        
        let controller = UIAlertController(
            title: NSLocalizedString("Notification", bundle:postingQueueManagerBundle(), comment: ""),
            message:NSLocalizedString("Mail.Message", bundle:postingQueueManagerBundle(), comment: ""),
            preferredStyle: .Alert)
        
        let otherAction = UIAlertAction(title: NSLocalizedString("Mail.Open", bundle:postingQueueManagerBundle(), comment: ""), style: .Default) {
            action in
            // check if can send an email
            if MFMailComposeViewController.canSendMail()==false {
                return
            }
            let postingEntry = self.postingQueueManager.postingEntries[self.index]
            
            let controller = MFMailComposeViewController()
            controller.mailComposeDelegate = self
            controller.setSubject(postingEntry.title!)
            controller.setMessageBody("", isHTML: false)

            // TODO:
            for filePath in postingEntry.filePaths() {
                let mimeType = self.mimeTypeForFilePath(filePath)
                if let data = NSFileManager.defaultManager().contentsAtPath(filePath) {
                    controller.addAttachmentData(data, mimeType: mimeType, fileName: filePath.lastPathComponent)
                }
            }
            self.presentViewController(controller, animated: true, completion: nil)
            
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", bundle:postingQueueManagerBundle(), comment: ""), style: .Cancel, handler: nil)
        controller.addAction(otherAction)
        controller.addAction(cancelAction)
        presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func onCopy(sender: AnyObject) {
        UIPasteboard.generalPasteboard().string = postingQueueManager.log(index)
        
        let controller = UIAlertController(
            title: NSLocalizedString("Notification", bundle:postingQueueManagerBundle(), comment: ""),
            message:NSLocalizedString("CopiedLog", bundle:postingQueueManagerBundle(), comment: ""),
            preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title:  NSLocalizedString("Ok", comment: ""), style: .Default, handler: nil)
        controller.addAction(defaultAction)
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        switch result.rawValue {
        case MFMailComposeResultCancelled.rawValue:
            break
        case MFMailComposeResultSaved.rawValue:
            break
        case MFMailComposeResultSent.rawValue:
            break
        case MFMailComposeResultFailed.rawValue:
            break
        default:
            break
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
