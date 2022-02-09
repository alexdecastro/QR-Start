//
//  REDCapUtilities.swift
//  QR Start
//
//  Created by Alex DeCastro on 11/9/2019.
//

import UIKit

class REDCapUtilities {
    
    // Write a value to REDCap
    static func writeValueToREDCap(
        token: String,
        pGUID: String,
        visit: String,
        dictionary: Dictionary<String,String>,
        completion:@escaping (( _ visit: String, _ success: Bool )-> Void)) {
        
        print("DEBUG: REDCapUtilities: writeValueToREDCap(pGUID: \(pGUID))")
        let url = URL(string: "https://abcd-rc.ucsd.edu/redcap/api/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        var payload = "[{\"id_redcap\":\"\(pGUID)\", \"redcap_event_name\":\"\(visit)\""
        for (key, value) in dictionary {
            payload = payload + ", \"\(key)\":\"\(value)\""
        }
        payload = payload + "}]"
        print("payload: \(payload)")
        
        let parameters: [String: Any] = [
            "token": token,
            "content": "record",
            "format": "json",
            "type": "flat",
            "overwriteBehavior": "overwrite",
            "forceAutoNumber": "false",
            "data": payload,
            "returnContent": "count",
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
            
            print("REDCapUtilities: writeValueToREDCap:----------")
            
            guard (200 ... 299) ~= response.statusCode else {
                // check for http errors
                let message = "ERROR: Cannot write to REDCap: response.statusCode should be 2xx, but is \(response.statusCode)"
                print("Error message: \(message)")
                print("response = \(response)")
                completion(message, false)
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("responseString = \(responseString)")
                if (responseString == "[]") {
                    let message = "ERROR: pGUID: '\(pGUID)' not found in REDCap."
                    completion(message, false)
                    return
                }
                
                let responseDict = convertJSONArrayToDictionary(text: responseString)
                print("responseDict: \(responseDict as AnyObject)")
                
                completion("some_timepoint_returned_by_writeValueToREDCap", true)
            }
        }
        
        task.resume()
    }

    // Utility to convert a JSON string into a dictionary
    // Allows the JSON string to be inside an array
    // https://stackoverflow.com/questions/47281375/convert-json-string-to-json-object-in-swift-4
    //
    static func convertJSONArrayToDictionary(text: String) -> [Dictionary<String,Any>]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Dictionary<String,Any>]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    // Open a REDCap form using the pGUID, visit and page name
    static func openREDCapForm(pGUID: String, visit: String, page: String) {
        var event_id: Int = 0
        if (visit == "baseline_year_1_arm_1") {
            event_id = 40
        } else if (visit == "1_year_follow_up_y_arm_1") {
                event_id = 41
        } else if (visit == "2_year_follow_up_y_arm_1") {
            event_id = 50
        } else if (visit == "3_year_follow_up_y_arm_1") {
            event_id = 61
        } else if (visit == "4_year_follow_up_y_arm_1") {
            event_id = 63
        } else if (visit == "5_year_follow_up_y_arm_1") {
            event_id = 65
        } else {
            print("ERROR: openREDCapForm: Invalid visit: \(visit)")
            return
        }
        print("event_id: \(event_id)")
        let urlString = "https://abcd-rc.ucsd.edu/redcap/redcap_v8.10.0/DataEntry/index.php?pid=12&id=\(pGUID)&event_id=\(event_id)&page=\(page)"
        print("Open REDCap URL: \(urlString)")
        UIApplication.shared.open(NSURL(string:urlString)! as URL)
    }
}
