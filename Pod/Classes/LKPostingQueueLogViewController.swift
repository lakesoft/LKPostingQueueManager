//
//  PostingQueueLogViewController.swift
//  Pods
//
//  Created by Hiroshi Hashiguchi on 2015/05/31.
//
//

import UIKit
import MessageUI

class LKPostingQueueLogViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var textView: UITextView!
    
    var postingQueueManager: LKPostingQueueManager!
    
    var index: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.text = postingQueueManager.log(index)
        title = NSLocalizedString("LogTitle", bundle:postingQueueManagerBundle(), comment: "")
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
            controller.setSubject(postingEntry.title)
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
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        
        switch result.value {
        case MFMailComposeResultCancelled.value:
            break
        case MFMailComposeResultSaved.value:
            break
        case MFMailComposeResultSent.value:
            break
        case MFMailComposeResultFailed.value:
            break
        default:
            break
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
