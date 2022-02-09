//
//  LoginTVC.swift
//  QR Start
//
//  Created by Alex DeCastro on 6/20/2019.
//

// MD5 stuff
import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

import UIKit

class LoginTVC: UITableViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var site: String?
    var username: String?
    var email: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        usernameTextField.becomeFirstResponder()
        usernameTextField.text = ""
        passwordTextField.text = ""
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if (Globals.release) {
            // Hide the skip log in button
            return 3
        } else {
            return 4
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        let segueIdentifier = segue.identifier
        print("LoginTVC: prepare: for segue: segueIdentifier: \(segueIdentifier ?? "nil")")
        
        if (segueIdentifier == "MainTVC") {
            let vc = segue.destination as! MainTVC
            vc.site = self.site
            vc.username = self.username
            vc.email = self.email
        }
    }
    
    // Handle table cell selections
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (indexPath.section == 2) {
            // Login button pressed
            tryToLogin()
        } else if (indexPath.section == 3) {
            skipLogin()
        }
    }
    
    // Skip login for testing purposes
    private func skipLogin() {
        self.site = "UCSD"
        self.username = "SECRET_USERNAME_HERE"
        self.email = "SECRET_EMAIL_HERE"
        self.performSegue(withIdentifier: "MainTVC", sender: nil)
    }
    
    // Try to log in
    private func tryToLogin() {
        if let username = usernameTextField.text,
            let password = passwordTextField.text {
            
            // Convert password to md5Hex
            let md5Data = MD5(string:password)
            let md5Hex =  md5Data.map { String(format: "%02hhx", $0) }.joined()
            print("md5Hex: \(md5Hex)")
            
            let md5Base64 = md5Data.base64EncodedString()
            print("md5Base64: \(md5Base64)")
            
            authenticateWithABCDReport(username: username, md5Hex: md5Hex, completion: { response,isMatch  in
                print("completion: response: \(response) isMatch: \(isMatch)")
                DispatchQueue.main.async {
                    
                    if (isMatch) {
                        // Login Successful
                        self.username = username
                        
                        let message = "'Succesfully logged in as: \(username)'"
                        self.presentAlertWithTitle(title: "Login Successful", message: message, options: ["OK"]) { (option) in
                            switch(option) {
                            case 0:
                                self.performSegue(withIdentifier: "MainTVC", sender: nil)
                                break
                            default:
                                break
                            }
                        }
                    } else {
                        // Login Failed
                        let message = "'Could not login in as: \(username)'"
                        self.presentAlertWithTitle(title: "Login Failed", message: message, options: ["OK"]) { (option) in
                            switch(option) {
                            case 0:
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
    
    private func authenticateWithABCDReport(
        username: String,
        md5Hex: String,
        completion: @escaping ( _ response: String, _ isMatch: Bool ) -> Void) {
        
        let url = URL(string: "https://SECRET_URL_HERE")!
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "ac": "log",
            "username": username,
            "pw": md5Hex,
            "url": "SECRET_KEYWORD_HERE",
            "name": ""
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
            
            guard (200 ... 299) ~= response.statusCode else {
                // check for http errors
                print("response = \(response)")
                let message = "ERROR: statusCode should be 2xx, but is \(response.statusCode) for URL: \(url)"
                completion(message, false)
                return
            }
            
            if var responseString = String(data: data, encoding: .utf8) {
                
                print("responseString = \(String(describing: responseString))")
                if (responseString == "") {
                    let message = "ERROR: LoginTVC.authenticateWithABCDReport(): responseString is empty."
                    completion(message, false)
                    return;
                }
                
                if (responseString.prefix(1) == "1") {
                    // Remove the first character '1' that is in front of the response string
                    responseString = String(responseString.dropFirst())
                }
                
                let responseDict = self.convertJSONToDictionary(text: responseString)
                print("responseDict: \(responseDict as AnyObject)")
                
                if let isMatch = responseDict?["match"] as! Bool? {
                    if (isMatch) {
                        if let email = responseDict?["message"] as! String?,
                            let site = responseDict?["site"] as! String? {
                            print("LoginTVC.authenticateWithABCDReport(): email: \(email)")
                            print("LoginTVC.authenticateWithABCDReport(): site: \(site)")
                            self.site = site
                            self.email = email
                            completion(responseString, isMatch)
                        }
                    } else {
                        let message = "ERROR: LoginTVC.authenticateWithABCDReport(): isMatch is false."
                        completion(message, false)
                    }
                } else {
                    let message = "ERROR: LoginTVC.authenticateWithABCDReport(): responseDict?['match'] not found."
                    completion(message, false)
                    return;
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
    
    // How can I convert a String to an MD5 hash in iOS using Swift?
    // https://stackoverflow.com/questions/32163848/how-can-i-convert-a-string-to-an-md5-hash-in-ios-using-swift
    //
    private func MD5(string: String) -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: length)
        
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }
}

