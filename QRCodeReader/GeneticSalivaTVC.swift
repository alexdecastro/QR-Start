//
//  GeneticSalivaTVC.swift
//  QR Start
//
//  Created by Alex DeCastro on 11/16/2019.
//

import UIKit

protocol GeneticSalivaTVCDelegate:class {
    func childVCDidSave(_ controller: GeneticSalivaTVC, text: String)
}

class GeneticSalivaTVC: UITableViewController, ChildVCDelegate {
    
    weak var delegate: GeneticSalivaTVCDelegate?

    // Inputs
    var site: String?
    var pGUID: String?
    var visit: String?
    var token: String?
    
    @IBOutlet weak var geneticSalivaBarcodeLabel: UILabel!
    
    private var segueIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let site = self.site else {
            print("ERROR: GeneticSalivaTVC: viewDidLoad: site was not set.")
            return
        }
        print("site: \(site)")
        
        guard let pGUID = self.pGUID else {
            print("ERROR: GeneticSalivaTVC: viewDidLoad: pGUID was not set.")
            return
        }
        print("pGUID: \(pGUID)")
        
        self.visit = "baseline_year_1_arm_1"
        
        guard let token = self.token else {
            print("ERROR: GeneticSalivaTVC: viewDidLoad: token was not set.")
            return
        }
        print("token: \(token)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("GeneticSalivaTVC: viewWillDisappear")
        if self.isMovingFromParent {
            print("GeneticSalivaTVC: isMovingFromParent")
            if (didEnterBackground) {
                self.delegate?.childVCDidSave(self, text: "")
            }
        }
    }
    
    var didEnterBackground = false
    func applicationDidEnterBackground() {
        print("GeneticSalivaTVC: applicationDidEnterBackground")
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
                REDCapUtilities.openREDCapForm(pGUID: pGUID, visit: visit, page: "genetic_saliva_rucdryouth")
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        segueIdentifier = segue.identifier
        print("GeneticSalivaTVC: prepare: for segue: segueIdentifier: \(segueIdentifier ?? "nil")")
        
        if (segueIdentifier == "FirstBarcode") {
            let vc = segue.destination as! ScannerVC
            vc.delegate = self
            vc.windowTitle = "Genetic Saliva"
        }
    }
    
    func childVCDidSave(_ controller: ScannerVC, text: String) {
        print("GeneticSalivaTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        let text = text.trimmingCharacters(in: CharacterSet(charactersIn: " \r\n"))
        print("GeneticSalivaTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        if (segueIdentifier == "FirstBarcode") {
            // Genetic Saliva = 12 to 14 digits. For example: 12345678901234
            if let range = text.range(of: "[0-9]{12,14}", options: .regularExpression) {
                let found = String(text[range])
                print("Barcode is correct: \(found)")
                geneticSalivaBarcodeLabel.text = found
                let dictionary = ["dna_saliva_inventory_homekit": found]
                writeBarcodeToREDCap(dictionary: dictionary)
            } else {
                controller.navigationController!.popViewController(animated: true)
                let title = "ERROR: Invalid barcode: \(text)"
                let message = "Expected 12 to 14 digit number. For example: 12345678901234"
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
