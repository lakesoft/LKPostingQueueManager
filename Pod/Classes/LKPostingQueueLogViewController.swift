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
    func stringByAppendingPathComponent(_ path: String) -> String {
        return (self as NSString).appendingPathComponent(path)
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
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(LKPostingQueueLogViewController.started(_:)), name: NSNotification.Name(rawValue: kLKPostingQueueManagerNotificationStarted), object: nil)

    }
    
    @objc func started(_ notification:Notification) {
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Privates
    func mimeTypeForFilePath(_ filePath: String) -> String {
        switch filePath.pathExtension.lowercased() {
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
    
    @IBAction func onSendMail(_ sender: AnyObject) {
        
        let controller = UIAlertController(
            title: NSLocalizedString("Notification", bundle:postingQueueManagerBundle(), comment: ""),
            message:NSLocalizedString("Mail.Message", bundle:postingQueueManagerBundle(), comment: ""),
            preferredStyle: .alert)
        
        let otherAction = UIAlertAction(title: NSLocalizedString("Mail.Open", bundle:postingQueueManagerBundle(), comment: ""), style: .default) {
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
                if let data = FileManager.default.contents(atPath: filePath) {
                    controller.addAttachmentData(data, mimeType: mimeType, fileName: filePath.lastPathComponent)
                }
            }
            self.present(controller, animated: true, completion: nil)
            
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", bundle:postingQueueManagerBundle(), comment: ""), style: .cancel, handler: nil)
        controller.addAction(otherAction)
        controller.addAction(cancelAction)
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func onCopy(_ sender: AnyObject) {
        UIPasteboard.general.string = postingQueueManager.log(index)
        
        let controller = UIAlertController(
            title: NSLocalizedString("Notification", bundle:postingQueueManagerBundle(), comment: ""),
            message:NSLocalizedString("CopiedLog", bundle:postingQueueManagerBundle(), comment: ""),
            preferredStyle: .alert)
        let defaultAction = UIAlertAction(title:  NSLocalizedString("Ok", comment: ""), style: .default, handler: nil)
        controller.addAction(defaultAction)
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result.rawValue {
        case MFMailComposeResult.cancelled.rawValue:
            break
        case MFMailComposeResult.saved.rawValue:
            break
        case MFMailComposeResult.sent.rawValue:
            break
        case MFMailComposeResult.failed.rawValue:
            break
        default:
            break
        }
        
        self.dismiss(animated: true, completion: nil)
    }

}
