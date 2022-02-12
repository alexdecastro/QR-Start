//
//  BabyTeethTVC.swift
//  QR Start
//
//  Created by Alex DeCastro on 11/16/2019.
//

import UIKit

protocol BabyTeethTVCDelegate:AnyObject {
    func childVCDidSave(_ controller: BabyTeethTVC, text: String)
}

class BabyTeethTVC: UITableViewController, ChildVCDelegate {
    
    weak var delegate: BabyTeethTVCDelegate?

    // Inputs
    var site: String?
    var pGUID: String?
    var visit: String?
    var token: String?
    
    @IBOutlet weak var babyTeethBarcodeLabel: UILabel!
    
    @IBOutlet weak var openREDCapTableViewCell: UITableViewCell!
    @IBOutlet weak var openREDCapButtonLabel: UILabel!
    
    private var segueIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let site = self.site else {
            print("ERROR: BabyTeethTVC: viewDidLoad: site was not set.")
            return
        }
        print("site: \(site)")
        
        self.pGUID = nil
        self.visit = "baseline_year_1_arm_1"
        
        guard let token = self.token else {
            print("ERROR: BabyTeethTVC: viewDidLoad: token was not set.")
            return
        }
        print("token: \(token)")
        
        self.openREDCapTableViewCell.isUserInteractionEnabled = false
        self.openREDCapButtonLabel.textColor = UIColor.gray
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("BabyTeethTVC: viewWillDisappear")
        if self.isMovingFromParent {
            print("BabyTeethTVC: isMovingFromParent")
            if (didEnterBackground) {
                self.delegate?.childVCDidSave(self, text: "")
            }
        }
    }
    
    var didEnterBackground = false
    func applicationDidEnterBackground() {
        print("BabyTeethTVC: applicationDidEnterBackground")
        didEnterBackground = true
    }
    
    // MARK: - Table view data source
    // Handle table cell selections
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("indexPath.section = \(indexPath.section)")
        print("indexPath.row = \(indexPath.row)")
        
        if ((indexPath.section == 1) && (indexPath.row == 0)) {
            if let pGUID = self.pGUID,
                let visit = self.visit {
                REDCapUtilities.openREDCapForm(pGUID: pGUID, visit: visit, page: "baby_teeth_parent")
            } else {
                print("ERROR: BabyTeethTVC: self.pGUID is nil")
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        segueIdentifier = segue.identifier
        print("BabyTeethTVC: prepare: for segue: segueIdentifier: \(segueIdentifier ?? "nil")")
        
        if (segueIdentifier == "FirstBarcode") {
            let vc = segue.destination as! ScannerVC
            vc.delegate = self
            vc.windowTitle = "Baby Teeth"
        }
    }
    
    func childVCDidSave(_ controller: ScannerVC, text: String) {
        print("BabyTeethTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        let text = text.trimmingCharacters(in: CharacterSet(charactersIn: " \r\n"))
        print("BabyTeethTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        if (segueIdentifier == "FirstBarcode") {
            var found = false
            // pGUID = NDAR_INV followed by 8 alphanumeric characters. For example: NDAR_INVTEST1234
            if let range = text.range(of: "^NDAR_INV[a-zA-Z0-9]{8}", options: .regularExpression) {
                let string = String(text[range])
                print("Scanned pGUID: \(string)")
                babyTeethBarcodeLabel.text = string
                self.pGUID = string
                found = true
            } else {
                if let range = text.range(of: "^INV[a-zA-Z0-9]{8}", options: .regularExpression) {
                    let string = "NDAR_" + String(text[range])
                    print("Scanned pGUID: \(string)")
                    babyTeethBarcodeLabel.text = string
                    self.pGUID = string
                    found = true
                } else {
                    if let range = text.range(of: "^[a-zA-Z0-9]{8}", options: .regularExpression) {
                        let string = "NDAR_INV" + String(text[range])
                        print("Scanned pGUID: \(string)")
                        babyTeethBarcodeLabel.text = string
                        self.pGUID = string
                        found = true
                    }
                }
            }
            if (found) {
                self.openREDCapTableViewCell.isUserInteractionEnabled = true
                self.openREDCapButtonLabel.textColor = view.tintColor
            } else {
                controller.navigationController!.popViewController(animated: true)
                let title = "ERROR: Invalid pGUID: \(text)"
                let message = "Expected NDAR_INV followed by 8 alphanumeric characters. For example: NDAR_INVTEST1234"
                self.pGUID = nil
                self.openREDCapTableViewCell.isUserInteractionEnabled = false
                self.openREDCapButtonLabel.textColor = UIColor.gray
                self.presentAlertWithTitle(title: title, message: message, options: ["OK"]) { (option) in
                    print("option: \(option)")
                    switch(option) {
                    case 0:
                        print("OK pressed")
                        break
                    default:
                        break
                    }
                }
            }
        } else {
            print("ERROR: childVCDidSave: segueIdentifier: \(segueIdentifier ?? "nil")")
        }
        controller.navigationController!.popViewController(animated: true)
    }
    
    private func writeBarcodeToREDCap(dictionary: Dictionary<String,String>) {
        var dictionaryWrittenToREDCap = "("
        for (key, value) in dictionary {
            dictionaryWrittenToREDCap = dictionaryWrittenToREDCap + "\"\(key)\":\"\(value)\" "
        }
        dictionaryWrittenToREDCap = dictionaryWrittenToREDCap + ")"
        print("DEBUG: writeBarcodeToREDCap(dictionary: \(dictionaryWrittenToREDCap)")
        
        if let pGUID = self.pGUID {
            guard let token = self.token else {
                print("ERROR: writeBarcodeToREDCap: self.token optional is nil")
                return
            }
            guard let visit = self.visit else {
                print("ERROR: writeBarcodeToREDCap: self.visit optional is nil")
                return
            }
            REDCapUtilities.writeValueToREDCap(token: token, pGUID: pGUID, visit: visit, dictionary: dictionary, completion: { visit,success in
                print("completion: expectedVisit: \(visit) success: \(success)")
                DispatchQueue.main.async {
                    if (success) {
                        print("DEBUG: writeBarcodeToREDCap: success: true visit: \(visit)")
                        self.presentAlertWithTitle(title: "SUCCESS: Saved barcode to REDCap", message: dictionaryWrittenToREDCap, options: ["OK"]) { (option) in
                            print("option: \(option)")
                            switch(option) {
                            case 0:
                                print("OK pressed")
                                break
                            default:
                                break
                            }
                        }
                    } else { // (!success)
                        self.presentAlertWithTitle(title: "ERROR: pGUID not in REDCap", message: visit, options: ["OK"]) { (option) in
                            print("option: \(option)")
                            switch(option) {
                            case 0:
                                print("OK pressed")
                                break
                            default:
                                break
                            }
                        }
                    }
                }
            })
        }
    }
}
