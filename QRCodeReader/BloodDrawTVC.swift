//
//  BloodDrawTVC.swift
//  QR Start
//
//  Created by Alex DeCastro on 8/24/2019.
//

import UIKit

protocol BloodDrawTVCDelegate:class {
    func childVCDidSave(_ controller: BloodDrawTVC, text: String)
}

class BloodDrawTVC: UITableViewController, ChildVCDelegate {
    
    weak var delegate: BloodDrawTVCDelegate?

    // Inputs
    var site: String?
    var pGUID: String?
    var visit: String?
    var token: String?
    
    @IBOutlet weak var firstBarcodeLabel: UILabel!
    @IBOutlet weak var secondBarcodeLabel: UILabel!
    @IBOutlet weak var thirdBarcodeLabel: UILabel!
    
    private var segueIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let site = self.site else {
            print("ERROR: BloodDrawTVC: viewDidLoad: site was not set.")
            return
        }
        print("site: \(site)")
        
        guard let pGUID = self.pGUID else {
            print("ERROR: BloodDrawTVC: viewDidLoad: pGUID was not set.")
            return
        }
        print("pGUID: \(pGUID)")
        
        if let visit = self.visit {
            if (visit == "2_year_follow_up_y_arm_1") {
                self.visit = "2_year_follow_up_y_arm_1"
            } else if (visit == "3_year_follow_up_y_arm_1") {
                self.visit = "3_year_follow_up_y_arm_1"
            } else if (visit == "4_year_follow_up_y_arm_1") {
                self.visit = "4_year_follow_up_y_arm_1"
            } else if (visit == "5_year_follow_up_y_arm_1") {
                self.visit = "5_year_follow_up_y_arm_1"
            } else {
                print("ERROR: BloodDrawTVC: viewDidLoad: Invalid visit: \(visit)")
                self.visit = nil
                return
            }
            print("visit: \(visit)")
        } else {
            print("ERROR: BloodDrawTVC: viewDidLoad: visit was not set.")
            return
        }
        
        guard let token = self.token else {
            print("ERROR: BloodDrawTVC: viewDidLoad: token was not set.")
            return
        }
        print("token: \(token)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("BloodDrawTVC: viewWillDisappear")
        if self.isMovingFromParent {
            print("BloodDrawTVC: isMovingFromParent")
            if (didEnterBackground) {
                self.delegate?.childVCDidSave(self, text: "")
            }
        }
    }
    
    var didEnterBackground = false
    func applicationDidEnterBackground() {
        print("BloodDrawTVC: applicationDidEnterBackground")
        didEnterBackground = true
    }
    
    // MARK: - Table view data source
    // Handle table cell selections
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("indexPath.section = \(indexPath.section)")
        print("indexPath.row = \(indexPath.row)")
        
        if ((indexPath.section == 3) && (indexPath.row == 0)) {
            if let pGUID = self.pGUID {
                if let visit = self.visit {
                    REDCapUtilities.openREDCapForm(pGUID: pGUID, visit: visit, page: "y_blood_draw")
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        segueIdentifier = segue.identifier
        print("BloodDrawTVC: prepare: for segue: segueIdentifier: \(segueIdentifier ?? "nil")")
        
        let vc = segue.destination as! ScannerVC
        vc.delegate = self
        if (segueIdentifier == "FirstBarcode") {
            vc.windowTitle = "Red Tube"
        } else if (segueIdentifier == "SecondBarcode") {
            vc.windowTitle = "Purple Tube"
        } else if (segueIdentifier == "ThirdBarcode") {
            vc.windowTitle = "Transfer Tube"
        } else {
            print("ERROR: Unknown segueIdentifier: \(String(describing: segueIdentifier))")
        }
    }
    
    func childVCDidSave(_ controller: ScannerVC, text: String) {
        print("BloodDrawTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        let text = text.trimmingCharacters(in: CharacterSet(charactersIn: " \r\n"))
        print("BloodDrawTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        if (segueIdentifier == "FirstBarcode") {
            // Red tube = TA followed by 7 digits. For example: TA1234567
            if let range = text.range(of: "TA0[0-9]{6}", options: .regularExpression) {
                let found = String(text[range])
                print("Red tube barcode is correct: \(found)")
                firstBarcodeLabel.text = found
                let dictionary = ["biospec_blood_tube1_barcode": found]
                writeBarcodeToREDCap(dictionary: dictionary)
            } else {
                controller.navigationController!.popViewController(animated: true)
                let title = "ERROR: Invalid red tube barcode: \(text)"
                let message = "Expected TA followed by 7 numbers. For example: TA1234567"
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
        } else if (segueIdentifier == "SecondBarcode") {
            // Purple tube = PA followed by 7 digits. For example: PA1234567
            //if let range = text.range(of: "[0-9]{7}", options: .regularExpression) {
            if let range = text.range(of: "PA0[0-9]{6}", options: .regularExpression) {
                let found = String(text[range])
                print("Purple tube barcode is correct: \(found)")
                secondBarcodeLabel.text = found
                let dictionary = ["biospec_blood_tube2_barcode": found]
                writeBarcodeToREDCap(dictionary: dictionary)
            } else {
                controller.navigationController!.popViewController(animated: true)
                let title = "ERROR: Invalid purple tube barcode: \(text)"
                let message = "Expected PA followed by 7 numbers. For example: PA1234567"
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
        } else if (segueIdentifier == "ThirdBarcode") {
            // Transfer =  10 digits. For example: 1234567890
            if let range = text.range(of: "[0-9]{10}", options: .regularExpression) {
                let found = String(text[range])
                print("Transfer tube barcode is correct: \(found)")
                thirdBarcodeLabel.text = found
                let dictionary = ["biospec_blood_fluidx_tube": found]
                writeBarcodeToREDCap(dictionary: dictionary)
            } else {
                controller.navigationController!.popViewController(animated: true)
                let title = "ERROR: Invalid transfer tube barcode: \(text)"
                let message = "Expected 10 numbers. For example: 1234567890"
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
                print("ERROR: writeBarcodeToREDCap: Could not find token")
                return
            }
            guard let visit = self.visit else {
                print("ERROR: writeBarcodeToREDCap: visit was not set.")
                return
            }
            REDCapUtilities.writeValueToREDCap(token: token, pGUID: pGUID, visit: visit, dictionary: dictionary, completion: { message,success in
                print("completion: expectedVisit: \(visit) success: \(success)")
                DispatchQueue.main.async {
                    if (success) {
                        print("DEBUG: writeBarcodeToREDCap: success: true visit: \(visit)")
                        self.presentAlertWithTitle(title: "SUCCESS: Saved barcode for visit: \(visit)", message: dictionaryWrittenToREDCap, options: ["OK"]) { (option) in
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
                        self.presentAlertWithTitle(title: "ERROR: writeValueToREDCap", message: message, options: ["OK"]) { (option) in
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

