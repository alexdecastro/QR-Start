//
//  PHSalivaTVC.swift
//  QR Start
//
//  Created by Alex DeCastro on 11/16/2019.
//

import UIKit

protocol PHSalivaTVCDelegate:class {
    func childVCDidSave(_ controller: PHSalivaTVC, text: String)
}

class PHSalivaTVC: UITableViewController, ChildVCDelegate {
    
    weak var delegate: PHSalivaTVCDelegate?

    // Inputs
    var site: String?
    var pGUID: String?
    var visit: String?
    var token: String?
    
    @IBOutlet weak var phSalivaBarcodeLabel: UILabel!
    
    private var segueIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let site = self.site else {
            print("ERROR: PHSalivaTVC: viewDidLoad: site was not set.")
            return
        }
        print("site: \(site)")
        
        guard let pGUID = self.pGUID else {
            print("ERROR: PHSalivaTVC: viewDidLoad: pGUID was not set.")
            return
        }
        print("pGUID: \(pGUID)")
        
        guard let visit = self.visit else {
            print("ERROR: PHSalivaTVC: viewDidLoad: visit was not set.")
            return
        }
        print("visit: \(visit)")
        
        guard let token = self.token else {
            print("ERROR: PHSalivaTVC: viewDidLoad: token was not set.")
            return
        }
        print("token: \(token)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("PHSalivaTVC: viewWillDisappear")
        if self.isMovingFromParent {
            print("PHSalivaTVC: isMovingFromParent")
            if (didEnterBackground) {
                self.delegate?.childVCDidSave(self, text: "")
            }
        }
    }
    
    var didEnterBackground = false
    func applicationDidEnterBackground() {
        print("PHSalivaTVC: applicationDidEnterBackground")
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
                REDCapUtilities.openREDCapForm(pGUID: pGUID, visit: visit, page: "pubertal_hormone_saliva_psyouth")
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        segueIdentifier = segue.identifier
        print("PHSalivaTVC: prepare: for segue: segueIdentifier: \(segueIdentifier ?? "nil")")
        
        if (segueIdentifier == "FirstBarcode") {
            let vc = segue.destination as! ScannerVC
            vc.delegate = self
            vc.windowTitle = "Pubertal Hormone Saliva"
        }
    }
    
    func childVCDidSave(_ controller: ScannerVC, text: String) {
        print("PHSalivaTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        let text = text.trimmingCharacters(in: CharacterSet(charactersIn: " \r\n"))
        print("PHSalivaTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        if (segueIdentifier == "FirstBarcode") {
            let (valid, message) = isValid(barcode: text)
            if (valid) {
                phSalivaBarcodeLabel.text = text
                let dictionary = ["hormone_sal_bc_y": text]
                writeBarcodeToREDCap(dictionary: dictionary)
            } else {
                controller.navigationController!.popViewController(animated: true)
                let title = "ERROR: Invalid barcode: \(text)"
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
    
    // Pubertal Hormone Saliva = [YBL,Y01,Y02,Y03]-PS##-###. For example: YBL-PS31-001
    private func isValid(barcode: String) -> (Bool, String) {
        var message = ""
        let components = barcode.components(separatedBy: "-")
        if (components.count != 3) {
            message = "ERROR: isValid: Barcode is not three strings separated by a dash. For example: YBL-PS31-001"
            return (false, message)
        }
        let first  = components[0]
        if (first.count != 3) {
            message = "ERROR: isValid: First part of barcode: \(first) is not three characters in length"
            return (false, message)
        }
        if (Globals.release) {
            if let visit = self.visit {
                if (visit == "baseline_year_1_arm_1") && (first != "YBL") {
                    message = "ERROR: isValid: First part of barcode: \(first) does not match the visit: \(visit)"
                    return (false, message)
                } else if (visit == "1_year_follow_up_y_arm_1") && (first != "Y01") {
                    message = "ERROR: isValid: First part of barcode: \(first) does not match the visit: \(visit)"
                    return (false, message)
                } else if (visit == "2_year_follow_up_y_arm_1") && (first != "Y02") {
                    message = "ERROR: isValid: First part of barcode: \(first) does not match the visit: \(visit)"
                    return (false, message)
                } else if (visit == "3_year_follow_up_y_arm_1") && (first != "Y03") {
                    message = "ERROR: isValid: First part of barcode: \(first) does not match the visit: \(visit)"
                    return (false, message)
                } else if (visit == "4_year_follow_up_y_arm_1") && (first != "Y04") {
                    message = "ERROR: isValid: First part of barcode: \(first) does not match the visit: \(visit)"
                    return (false, message)
                } else if (visit == "5_year_follow_up_y_arm_1") && (first != "Y05") {
                    message = "ERROR: isValid: First part of barcode: \(first) does not match the visit: \(visit)"
                    return (false, message)
                } else {
                    // do nothing, assume everything is ok so far
                }
            } else {
                message = "ERROR: isValid: Invalid self.visit: \(String(describing: self.visit))"
                return (false, message)
            }
        }
        let second = components[1]
        if (second.count != 4) {
            message = "ERROR: isValid: Second part of barcode: \(second) is not four characters"
            return (false, message)
        }
        let third  = components[2]
        if (third.count != 3) {
            message = "ERROR: isValid: Third part of barcode: \(third) is not three numbers"
            return (false, message)
        }
        return (true, "")
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

