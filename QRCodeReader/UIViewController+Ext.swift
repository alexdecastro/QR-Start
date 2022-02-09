//
//  UIViewController+Ext.swift
//  QR Start
//
//  Created by Alex DeCastro on 6/19/2019.
//

import UIKit

extension UIViewController {
    
    // Swift Displaying Alerts best practices
    // https://stackoverflow.com/questions/29633938/swift-displaying-alerts-best-practices
    //
    func presentAlertWithTitle(title: String, message: String, options: [String], completion: @escaping (Int) -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for (index, option) in options.enumerated() {
            alertController.addAction(UIAlertAction.init(title: option, style: .default, handler: { (action) in
                completion(index)
            }))
        }
        self.present(alertController, animated: true, completion: nil)
    }
    
    func test() {
        presentAlertWithTitle(title: "Test", message: "A message", options: ["1", "2"]) { (option) in
            print("option: \(option)")
            switch(option) {
            case 0:
                print("option one")
                break
            case 1:
                print("option two")
            default:
                break
            }
        }
    }
}
