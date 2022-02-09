//
//  MainTVC.swift
//  QR Start
//
//  Created by Alex DeCastro on 5/18/2019.
//

import UIKit

extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
            }
            .joined(separator: "&")
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

class MainTVC: UITableViewController, ChildVCDelegate, MillisecondVCDelegate, KsadsVCDelegate, BloodDrawTVCDelegate, HairSampleTVCDelegate, PHSalivaTVCDelegate, GeneticSalivaTVCDelegate, BabyTeethTVCDelegate {

    // Force RA to rescan wristband
    var shouldResetWristband = true
    
    // Inactivity timer
    var timer = Timer()

    // input
    var site: String?
    var username: String?
    var email: String?
    @IBOutlet weak var loginInfoLabel: UILabel!
    
    @IBOutlet weak var firstBarcodeLabel: UILabel!
    
    @IBOutlet weak var secondBarcodeTableViewCell: UITableViewCell!
    @IBOutlet weak var secondBarcodeButtonLabel: UILabel!
    @IBOutlet weak var secondBarcodeLabel: UILabel!
    
    @IBOutlet weak var barcodeMatchTableViewCell: UITableViewCell!
    @IBOutlet weak var barcodeMatchLabel: UILabel!
    
    @IBOutlet weak var selectedVisitLabel: UILabel!
    
    @IBOutlet weak var redcapTableViewCell: UITableViewCell!
    @IBOutlet weak var redcapButtonLabel: UILabel!
    
    private var segueIdentifier: String?
    
    private let tokenDictionary =
        ["TEST": Constants.API.TEST,
         "TESTFITBIT": Constants.API.TESTFITBIT,
         "UCSD": Constants.API.UCSD,
         "UCLA": Constants.API.UCLA,
         "YALE": Constants.API.YALE,
         "WUSTL": Constants.API.WUSTL,
         "VCU": Constants.API.VCU,
         "UVM": Constants.API.UVM,
         "UTAH": Constants.API.UTAH,
         "UPMC": Constants.API.UPMC,
         "UMN": Constants.API.UMN,
         "UMICH": Constants.API.UMICH,
         "OAHU": Constants.API.OAHU,
         "UMB": Constants.API.UMB,
         "UFL": Constants.API.UFL,
         "CUB": Constants.API.CUB,
         "SRI": Constants.API.SRI,
         "OHSU": Constants.API.OHSU,
         "LIBR": Constants.API.LIBR,
         "MSSM": Constants.API.MSSM,
         "FIU": Constants.API.FIU,
         "CHLA": Constants.API.CHLA,
         "MGH": Constants.API.MGH,
         "MUSC": Constants.API.MUSC,
         "UWM": Constants.API.UWM,
         "ROC": Constants.API.ROC]
    
    private let visitDictionary =
        ["baseline_year_1_arm_1": "Baseline (Year 1)",
         "6_month_follow_up_arm_1": "6 month Follow up (Year 0.5)",
         "1_year_follow_up_y_arm_1": "1 Year Follow up (Year 2)",
         "18_month_follow_up_arm_1": "18 month Follow up (Year 2.5)",
         "2_year_follow_up_y_arm_1": "2 Year Follow up (Year 3)",
         "30_month_follow_up_arm_1": "30 month Follow up (Year 3.5)",
         "3_year_follow_up_y_arm_1": "3 Year Follow up (Year 4)",
         "42_month_follow_up_arm_1": "42 month Follow up (Year 4.5)",
         "4_year_follow_up_y_arm_1": "4 Year Follow up (Year 5)",
         "54_month_follow_up_arm_1": "54 month Follow up (Year 5.5)",
         "5_year_follow_up_y_arm_1": "5 Year Follow up (Year 6)"]
    
    private var hideTasks = true
    
    private var pGUID: String?
    private func setpGUID(newValue: String?) {
        pGUID = newValue
        if let n = newValue {
            barcodeMatchLabel.text = "pGUID: \(n)"
            barcodeMatchLabel.textColor = view.tintColor
            barcodeMatchLabel.backgroundColor = UIColor.init(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.25)
        } else {
            barcodeMatchLabel.text = "No pGUID"
            barcodeMatchLabel.textColor = UIColor.gray
            barcodeMatchLabel.backgroundColor = UIColor.white
        }
    }
    
    private var selectedVisit: String?
    private func setSelectedVisit(newValue: String?) {
        selectedVisit = newValue
        if let n = newValue,
            let text = visitDictionary[n] {
            selectedVisitLabel.text = "Visit: \(text)"
            selectedVisitLabel.textColor = UIColor.black
            selectedVisitLabel.backgroundColor = UIColor.white
            enableTaskButtons(enable: true)
        } else {
            selectedVisitLabel.text = "No visit"
            selectedVisitLabel.textColor = UIColor.gray
            selectedVisitLabel.backgroundColor = UIColor.white
            enableTaskButtons(enable: false)
        }
    }
    
    // Enable buttons to open tasks
    private func enableTaskButtons(enable: Bool) {
        self.hideTasks = !enable
        self.barcodeMatchTableViewCell.isUserInteractionEnabled = enable
        self.redcapTableViewCell.isUserInteractionEnabled = enable
        if (enable) {
            redcapButtonLabel.textColor = view.tintColor
        } else {
            redcapButtonLabel.textColor = UIColor.gray
        }
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let site = self.site else {
            print("ERROR: MainTVC: viewDidLoad: site was not set.")
            return
        }
        guard let username = self.username else {
            print("ERROR: MainTVC: viewDidLoad: username was not set.")
            return
        }
        guard let email = self.email else {
            print("ERROR: MainTVC: viewDidLoad: email was not set.")
            return
        }
        let loginInfo = "Site: \(site) User: \(username) Email: \(email)"
        self.loginInfoLabel.text = loginInfo
        print("MainTVC: viewDidLoad: loginInfo: \(loginInfo)")
        
        if (username == "SECRET_USERNAME_HERE") {
            firstBarcodeLabel.text = "SECRET_ALT_ID_HERE"
            
            secondBarcodeTableViewCell.isUserInteractionEnabled = true
            secondBarcodeButtonLabel.textColor = view.tintColor
            secondBarcodeLabel.text = "NDAR_INVTEST1234"
            
            setpGUID(newValue: "NDAR_INVTEST1234")
            setSelectedVisit(newValue: "5_year_follow_up_y_arm_1")
        } else {
            secondBarcodeTableViewCell.isUserInteractionEnabled = false
            secondBarcodeButtonLabel.textColor = UIColor.gray
            
            setpGUID(newValue: nil)
            setSelectedVisit(newValue: nil)
        }
    }

    func applicationDidEnterBackground() {
        print("MainTVC: applicationDidEnterBackground:")
        resetWristband(force: false)
    }

    func applicationDidQRTimeout() {
        print("MainTVC: applicationDidQRTimeout:")
        resetWristband(force: true)
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ((self.hideTasks) && ((section == 4) || (section == 5))) {
            return 0
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if ((self.hideTasks) && ((section == 4) || (section == 5))) {
            return nil
        }
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        segueIdentifier = segue.identifier
        print("MainTVC: prepare: for segue: segueIdentifier: \(segueIdentifier ?? "nil")")
        
        if (segueIdentifier == "FirstBarcode") {
            let vc = segue.destination as! ScannerVC
            vc.delegate = self
            vc.windowTitle = "Wristband QR code"
        } else if (segueIdentifier == "SecondBarcode") {
            let vc = segue.destination as! ScannerVC
            vc.delegate = self
            vc.windowTitle = "pGUID barcode label"
        } else if (segueIdentifier == "MillisecondVC") {
            let vc = segue.destination as! MillisecondVC
            vc.delegate = self
            vc.site = self.site
            vc.pGUID = self.pGUID
            vc.visit = self.selectedVisit
        } else if (segueIdentifier == "ParentKsadsVC") {
            let vc = segue.destination as! KsadsVC
            vc.delegate = self
            vc.site = self.site
            vc.pGUID = self.pGUID
            vc.visit = self.selectedVisit
            vc.email = self.email
            vc.selectedParentTeen = "Parent"
        } else if (segueIdentifier == "TeenKsadsVC") {
            let vc = segue.destination as! KsadsVC
            vc.delegate = self
            vc.site = self.site
            vc.pGUID = self.pGUID
            vc.visit = self.selectedVisit
            vc.email = self.email
            vc.selectedParentTeen = "Teen"
            vc.selectedLanguage = "English"
        } else if (segueIdentifier == "BloodDrawTVC") {
            let vc = segue.destination as! BloodDrawTVC
            vc.delegate = self
            vc.site = self.site
            vc.pGUID = self.pGUID
            vc.visit = self.selectedVisit
            
            // get the token for the selected site
            guard let site = self.site else {
                print("ERROR: prepare:for segue: self.site was not set.")
                return
            }
            guard let token = tokenDictionary[site] else {
                print("ERROR: prepare:for segue: Could not find token for site: \(site)")
                return
            }
            vc.token = token
        } else if (segueIdentifier == "HairSampleTVC") {
            let vc = segue.destination as! HairSampleTVC
            vc.delegate = self
            vc.site = self.site
            vc.pGUID = self.pGUID
            vc.visit = self.selectedVisit
            
            // get the token for the selected site
            guard let site = self.site else {
                print("ERROR: prepare:for segue: self.site was not set.")
                return
            }
            guard let token = tokenDictionary[site] else {
                print("ERROR: prepare:for segue: Could not find token for site: \(site)")
                return
            }
            vc.token = token
        } else if (segueIdentifier == "PHSalivaTVC") {
            let vc = segue.destination as! PHSalivaTVC
            vc.delegate = self
            vc.site = self.site
            vc.pGUID = self.pGUID
            vc.visit = self.selectedVisit
            
            // get the token for the selected site
            guard let site = self.site else {
                print("ERROR: prepare:for segue: self.site was not set.")
                return
            }
            guard let token = tokenDictionary[site] else {
                print("ERROR: prepare:for segue: Could not find token for site: \(site)")
                return
            }
            vc.token = token
        } else if (segueIdentifier == "GeneticSalivaTVC") {
            let vc = segue.destination as! GeneticSalivaTVC
            vc.delegate = self
            vc.site = self.site
            vc.pGUID = self.pGUID
            vc.visit = self.selectedVisit
            
            // get the token for the selected site
            guard let site = self.site else {
                print("ERROR: prepare:for segue: self.site was not set.")
                return
            }
            guard let token = tokenDictionary[site] else {
                print("ERROR: prepare:for segue: Could not find token for site: \(site)")
                return
            }
            vc.token = token
        } else if (segueIdentifier == "BabyTeethTVC") {
            let vc = segue.destination as! BabyTeethTVC
            vc.delegate = self
            vc.site = self.site
            vc.pGUID = self.pGUID
            vc.visit = self.selectedVisit
            
            // get the token for the selected site
            guard let site = self.site else {
                print("ERROR: prepare:for segue: self.site was not set.")
                return
            }
            guard let token = tokenDictionary[site] else {
                print("ERROR: prepare:for segue: Could not find token for site: \(site)")
                return
            }
            vc.token = token
        } else {
            print("ERROR: Unknown segueIdentifier: \(String(describing: segueIdentifier))")
        }
    }
    
    func childVCDidSave(_ controller: ScannerVC, text: String) {
        print("MainTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        let text = text.trimmingCharacters(in: CharacterSet(charactersIn: " \r\n"))
        print("MainTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        if (segueIdentifier == "FirstBarcode") {
            // AlternateID = 8 alphanumeric characters.
            if let range = text.range(of: "^[a-zA-Z0-9]{8}$", options: .regularExpression) {
                let string = String(text[range])
                print("Alternate ID: \(string)")
                firstBarcodeLabel.text = string
                secondBarcodeTableViewCell.isUserInteractionEnabled = true
                secondBarcodeButtonLabel.textColor = view.tintColor
                checkIfBarcodesMatch()
            } else {
                controller.navigationController!.popViewController(animated: true)
                let title = "ERROR: Invalid Alternate ID: \(text)"
                let message = "Expected 8 alphanumeric characters."
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
            var found = false
            // pGUID = NDAR_INV followed by 8 alphanumeric characters. For example: NDAR_INVTEST1234
            if let range = text.range(of: "^NDAR_INV[a-zA-Z0-9]{8}$", options: .regularExpression) {
                let string = String(text[range])
                print("Scanned pGUID: \(string)")
                secondBarcodeLabel.text = string
                found = true
            } else {
                if let range = text.range(of: "^INV[a-zA-Z0-9]{8}$", options: .regularExpression) {
                    let string = "NDAR_" + String(text[range])
                    print("Scanned pGUID: \(string)")
                    secondBarcodeLabel.text = string
                    found = true
                } else {
                    if let range = text.range(of: "^[a-zA-Z0-9]{8}$", options: .regularExpression) {
                        let string = "NDAR_INV" + String(text[range])
                        print("Scanned pGUID: \(string)")
                        secondBarcodeLabel.text = string
                        found = true
                    }
                }
            }
            if (found) {
                checkIfBarcodesMatch()
            } else {
                controller.navigationController!.popViewController(animated: true)
                let title = "ERROR: Invalid pGUID: \(text)"
                let message = "Expected NDAR_INV followed by 8 alphanumeric characters. For example: NDAR_INVTEST1234"
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
    
    private func checkIfBarcodesMatch() {
        enableTaskButtons(enable: false)
        if ((firstBarcodeLabel.text == "--------") ||
            (secondBarcodeLabel.text == "--------")) {
            setpGUID(newValue: nil)
            return
        }
        if let site = self.site,
            let alternateID = firstBarcodeLabel.text,
            let pGUID = secondBarcodeLabel.text {
            checkIfpGUIDAndAlternateIDMatch(site: site, pGUID: pGUID, alternateID: alternateID, completion: { response,isMatch  in
                print("completion: response: \(response) isMatch: \(isMatch)")
                DispatchQueue.main.async {
                    self.updateMatchLabel(response: response, isMatch: isMatch)
                }
            })
        }
    }
    
    // Check the PII database to see if the pGUID and alternate ID match
    private func checkIfpGUIDAndAlternateIDMatch(
        site: String,
        pGUID: String,
        alternateID: String,
        completion: @escaping ( _ response: String, _ isMatch: Bool ) -> Void) {
        
        let url = URL(string: "https://SECRET_LOGIN_URL_HERE")!
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "action": "checkMatch",
            "site": site,
            "pGUID": pGUID,
            "alternateID": alternateID,
            "array": ["1","2","3"]
        ]
        print("DEBUG: checkIfpGUIDAndAlternateIDMatch: parameters: \(parameters)")
        
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {
                    // check for fundamental networking error
                    print("error", error ?? "Unknown error")
                    return
            }
            
            print("checkIfpGUIDAndAlternateIDMatch:----------")
            
            guard (200 ... 299) ~= response.statusCode else {
                // check for http errors
                print("response = \(response)")
                let message = "ERROR: statusCode should be 2xx, but is \(response.statusCode) for URL: \(url)"
                completion(message, false)
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("responseString = \(String(describing: responseString))")
                if (responseString == "") {
                    let message = "ERROR: checkIfpGUIDAndAlternateIDMatch: responseString is empty."
                    completion(message, false)
                    return;
                }
                let responseDict = self.convertJSONToDictionary(text: responseString)
                print("responseDict: \(responseDict as AnyObject)")

                // responseMessage
                guard let responseMessage = responseDict?["message"] as! String? else {
                    let message = "ERROR: checkIfpGUIDAndAlternateIDMatch: responseDict?['message'] not found."
                    completion(message, false)
                    return
                }
                // ok
                guard let ok = responseDict?["ok"] as! Bool? else {
                    let message = "ERROR: checkIfpGUIDAndAlternateIDMatch: responseDict?['ok'] not found."
                    completion(message, false)
                    return
                }
                if (!ok) {
                    completion(responseMessage, false)
                    return
                }
                // match
                guard let match = responseDict?["match"] as! Bool? else {
                    let message = "ERROR: checkIfpGUIDAndAlternateIDMatch: responseDict?['match'] not found."
                    completion(message, false)
                    return
                }
                if (!match) {
                    completion(responseMessage, false)
                    return
                }
                // version
                guard let version = responseDict?["version"] as! String? else {
                    let message = "ERROR: checkIfpGUIDAndAlternateIDMatch: responseDict?['version'] not found."
                    completion(message, false)
                    return
                }
                // resetqr
                guard let resetqr = responseDict?["resetqr"] as! Bool? else {
                    let message = "ERROR: checkIfpGUIDAndAlternateIDMatch: responseDict?['resetqr'] not found."
                    completion(message, false)
                    return
                }
                self.shouldResetWristband = resetqr
                completion(version, true)
                return
            }
        }
        
        task.resume()
    }
    
    // Update the label that shows if the pGUID and alternate ID match
    private func updateMatchLabel(response: String, isMatch: Bool) {
        if (!isMatch) {
            let title = "Alternate ID does not match pGUID"
            barcodeMatchLabel.text = title
            barcodeMatchLabel.textColor = UIColor.black
            barcodeMatchLabel.backgroundColor = UIColor.red
            
            self.presentAlertWithTitle(title: title, message: response, options: ["OK"]) { (option) in
                print("option: \(option)")
                switch(option) {
                case 0:
                    // do nothing
                    break
                default:
                    break
                }
            }
            return;
        }
        
        if let serverVersion = Float(response) {
            if (Globals.appVersion < serverVersion) {
                let title = "Update the QR Start app"
                let message = "App version: \(Globals.appVersion) is older than the latest version: \(serverVersion)"
                barcodeMatchLabel.text = title
                barcodeMatchLabel.textColor = UIColor.black
                barcodeMatchLabel.backgroundColor = UIColor.red

                self.presentAlertWithTitle(title: title, message: message, options: ["OK"]) { (option) in
                    print("option: \(option)")
                    switch(option) {
                    case 0:
                        // do nothing
                        break
                    default:
                        break
                    }
                }
                return;
            } else {
                print("App version: \(Globals.appVersion) is the same or newer than the latest version: \(serverVersion)")
            }
        }
        
        if let pGUID = secondBarcodeLabel.text {
            
            setpGUID(newValue: pGUID)
            
            guard let site = self.site else {
                print("ERROR: updateMatchLabel: self.site was not set.")
                return
            }
            readVisitFromREDCap(site: site, pGUID: pGUID, completion: { visit,success in
                print("completion: expectedVisit: \(visit) success: \(success)")
                DispatchQueue.main.async {
                    if (success) {
                        let expectedVisit = visit
                        print("DEBUG: updateMatchLabel: Found expectedVisit: \(expectedVisit)")

                        // Check if annual visit is correct
                        if ((expectedVisit == "1_year_follow_up_y_arm_1") ||
                            (expectedVisit == "2_year_follow_up_y_arm_1") ||
                            (expectedVisit == "3_year_follow_up_y_arm_1") ||
                            (expectedVisit == "4_year_follow_up_y_arm_1") ||
                            (expectedVisit == "5_year_follow_up_y_arm_1")) {
                            let title = "\(self.visitDictionary[expectedVisit] ?? "Unknown visit")"
                            let message = "Is this the correct visit?"
                            self.presentAlertWithTitle(title: title, message: message, options: ["Yes", "No"]) { (option) in
                                print("option: \(option)")
                                switch(option) {
                                case 0:
                                    print("The RA confirmed the expected visit is correct.")
                                    self.setSelectedVisit(newValue: expectedVisit)
                                    self.enableTaskButtons(enable: true)
                                    break
                                case 1:
                                    print("The RA says expected visit is wrong, so ask them to select a visit.")
                                    self.askRAToSelectVisit(expectedVisit: expectedVisit)
                                    break
                                default:
                                    break
                                }
                            }
                        } else {
                            print("ERROR: The visit returned from REDCap is not an expected value.")
                            self.askRAToSelectVisit(expectedVisit: expectedVisit)
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
    
    // Ask the RA to select a visit
    private func askRAToSelectVisit(expectedVisit: String) {
        let message = "What is the correct visit?"
        let options = [visitDictionary["1_year_follow_up_y_arm_1"]!,
                       visitDictionary["2_year_follow_up_y_arm_1"]!,
                       visitDictionary["3_year_follow_up_y_arm_1"]!,
                       visitDictionary["4_year_follow_up_y_arm_1"]!,
                       visitDictionary["5_year_follow_up_y_arm_1"]!,
                       "Don't know"]
        
        self.presentAlertWithTitle(title: "Select Visit", message: message, options: options) { (option) in
            print("option: \(option)")
            switch(option) {
            case 0:
                self.setSelectedVisit(newValue: "1_year_follow_up_y_arm_1")
                break
            case 1:
                self.setSelectedVisit(newValue: "2_year_follow_up_y_arm_1")
                break
            case 2:
                self.setSelectedVisit(newValue: "3_year_follow_up_y_arm_1")
                break
            case 3:
                self.setSelectedVisit(newValue: "4_year_follow_up_y_arm_1")
                break
            case 4:
                self.setSelectedVisit(newValue: "5_year_follow_up_y_arm_1")
                break
            case 5: // The RA doesn't know
                self.setSelectedVisit(newValue: nil)
                self.enableTaskButtons(enable: false)
                let message = "Please find out the correct visit, then scan the wristband again."
                self.presentAlertWithTitle(title: "ERROR: Find out the visit.", message: message, options: ["OK"]) { (option) in
                    print("option: \(option)")
                    switch(option) {
                    case 0:
                        print("OK pressed")
                        break
                    default:
                        break
                    }
                }
                break
            default:
                break
            }
        }
    }
    
    // Read the expected visit from REDCap
    private func readVisitFromREDCap(
        site: String,
        pGUID: String,
        completion:@escaping (( _ visit: String, _ success: Bool )-> Void)) {
        
        let url = URL(string: "https://abcd-rc.ucsd.edu/redcap/api/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        guard let token = tokenDictionary[site] else {
            print("ERROR: readVisitFromREDCap: Could not find token for site: \(site)")
            return
        }
        
        let parameters: [String: Any] = [
            "token": token,
            "content": "record",
            "format": "json",
            "type": "flat",
            "records[0]": pGUID,
            "fields[0]": "sched_current_event_done",
            "fields[1]": "sched_last_event",
            "events[0]": "screener_arm_1",
            "rawOrLabel": "raw",
            "rawOrLabelHeaders": "raw",
            "exportCheckboxLabel": "false",
            "exportSurveyFields": "false",
            "exportDataAccessGroups": "false",
            "returnFormat": "json"
        ]
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {
                    // check for fundamental networking error
                    print("error", error ?? "Unknown error")
                    return
            }
            
            print("readVisitFromREDCap:----------")
            
            guard (200 ... 299) ~= response.statusCode else {
                // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("responseString = \(responseString)")
                if (responseString == "[]") {
                    let message = "ERROR: pGUID: '\(pGUID)' not found in REDCap."
                    completion(message, false)
                    return
                }
                
                let responseDict = REDCapUtilities.convertJSONArrayToDictionary(text: responseString)
                print("responseDict: \(responseDict as AnyObject)")
                
                if let sched_current_event_done = responseDict?[0]["sched_current_event_done"] {
                    print("sched_current_event_done: \(String(describing: sched_current_event_done))")
                    let sched_current_event_done_items = (sched_current_event_done as! String).split(separator: ",")
                    print("sched_current_event_done_items: '\(sched_current_event_done_items)'")
                    if (sched_current_event_done_items.count > 2) {
                        let sched_current_event_done_visit = sched_current_event_done_items[1].trimmingCharacters(in: .whitespaces)
                        print("sched_current_event_done_visit: '\(sched_current_event_done_visit)'")
                    }
                }
                
                if let sched_last_event = responseDict?[0]["sched_last_event"] {
                    print("sched_last_event: \(String(describing: sched_last_event))")
                    let sched_last_event_items = (sched_last_event as! String).split(separator: ",")
                    print("sched_last_event_items: '\(sched_last_event_items)'")
                    if (sched_last_event_items.count == 2) {
                        let sched_last_event_visit = sched_last_event_items[0].trimmingCharacters(in: .whitespaces)
                        print("sched_last_event_visit: '\(sched_last_event_visit)'")
                        completion(sched_last_event_visit, true)
                    }
                }
            }
        }
        
        task.resume()
    }
    
    // Utility to convert a JSON string into a dictionary
    private func convertJSONToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func childVCDidSave(_ controller: MillisecondVC, text: String) {
        print("MainTVC: childVCDidSave: MillisecondVC: text: \(text)")
        resetWristband(force: false)
    }
    
    func childVCDidSave(_ controller: KsadsVC, text: String) {
        print("MainTVC: childVCDidSave: KsadsVC: text: \(text)")
        resetWristband(force: false)
    }
    
    func childVCDidSave(_ controller: BloodDrawTVC, text: String) {
        print("MainTVC: childVCDidSave: BloodDrawTVC: text: \(text)")
        resetWristband(force: false)
    }
    
    func childVCDidSave(_ controller: HairSampleTVC, text: String) {
        print("MainTVC: childVCDidSave: HairSampleTVC: text: \(text)")
        resetWristband(force: false)
    }
    
    func childVCDidSave(_ controller: PHSalivaTVC, text: String) {
        print("MainTVC: childVCDidSave: PHSalivaTVC: text: \(text)")
        resetWristband(force: false)
    }
    
    func childVCDidSave(_ controller: GeneticSalivaTVC, text: String) {
        print("MainTVC: childVCDidSave: GeneticSalivaTVC: text: \(text)")
        resetWristband(force: false)
    }
    
    func childVCDidSave(_ controller: BabyTeethTVC, text: String) {
        print("MainTVC: childVCDidSave: BabyTeethTVC: text: \(text)")
        resetWristband(force: false)
    }
    
    // Handle table cell selections
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("indexPath.section = \(indexPath.section)")
        print("indexPath.row = \(indexPath.row)")
        
        if ((indexPath.section == 3) && (indexPath.row == 0)) {
            if let pGUID = secondBarcodeLabel.text {
                copypGUID(pGUID: pGUID)
            }
        }
        if ((indexPath.section == 4) && (indexPath.row == 0)) {
             // Open the REDCap parent consent form
            if let pGUID = secondBarcodeLabel.text,
                let visit = self.selectedVisit {
                REDCapUtilities.openREDCapForm(pGUID: pGUID, visit: visit, page: "permission")
                resetWristband(force: false)
            }
        }
        if ((indexPath.section == 5) && (indexPath.row == 0)) {
            // Open the REDCap child assent form
            if let pGUID = secondBarcodeLabel.text,
                let visit = self.selectedVisit {
                REDCapUtilities.openREDCapForm(pGUID: pGUID, visit: visit, page: "assent")
                resetWristband(force: false)
            }
        }
        if ((indexPath.section == 7) && (indexPath.row == 0)) {
            reset()
        }
        if ((indexPath.section == 7) && (indexPath.row == 1)) {
            logout()
        }
    }
    
    // Reset the page
    private func reset() {
        self.firstBarcodeLabel.text = "--------"
        self.secondBarcodeLabel.text = "--------"
        
        self.secondBarcodeTableViewCell.isUserInteractionEnabled = false
        self.secondBarcodeButtonLabel.textColor = UIColor.gray
        
        setpGUID(newValue: nil)
        setSelectedVisit(newValue: nil)
    }
    
    // Reset the wristband QR code
    private func resetWristband(force: Bool) {

        // During testing, don't reset the QR code
        if (!force) {
            if ((!shouldResetWristband) ||
                (self.username == "SECRET_USERNAME_HERE")) {
                return
            }
        }
        print("MainTVC: resetWristband")
        self.firstBarcodeLabel.text = "--------"
        setpGUID(newValue: nil)
        setSelectedVisit(newValue: nil)
        let message = "The wristband QR code needs to be scanned again after before you begin a new task. "
        self.presentAlertWithTitle(title: "Scan wristband again", message: message, options: ["OK"]) { (option) in
            print("option: \(option)")
            switch(option) {
            case 0:
                print("OK pressed")
                self.performSegue(withIdentifier: "FirstBarcode", sender: self)
                break
            default:
                break
            }
        }
    }
    
    // Reset the page
    private func logout() {
    }
    
    private func copypGUID(pGUID: String) {
        UIPasteboard.general.string = pGUID
        let message = "\(pGUID)"
        self.presentAlertWithTitle(title: "Copied pGUID", message: message, options: ["OK"]) { (option) in
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

