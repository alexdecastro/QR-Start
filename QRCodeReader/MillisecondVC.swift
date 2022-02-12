//
//  MillisecondVC.swift
//  QR Start
//
//  Created by Alex DeCastro on 6/15/2019.
//

import UIKit

protocol MillisecondVCDelegate:AnyObject {
    func childVCDidSave(_ controller: MillisecondVC, text: String)
}

class MillisecondVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: MillisecondVCDelegate?
    
    // Inputs
    var site: String?
    var pGUID: String?
    var visit: String?
    var visitSectionIndex: Int!
    
    @IBOutlet weak var infoTableView: UITableView!
    @IBOutlet weak var taskListTableView: UITableView!
    
    var startTaskCell: UITableViewCell!
    
    let infoSectionTitles = ["pGUID", "Visit", "Select a session"]
    let infoCellTitles =
        [[""],
         [""],
         ["1", "2", "3"]]
    
    let visitDictionary =
        ["1_year_follow_up_y_arm_1": "1-year follow-up",
         "2_year_follow_up_y_arm_1": "2-year follow-up",
         "3_year_follow_up_y_arm_1": "3-year follow-up",
         "4_year_follow_up_y_arm_1": "4-year follow-up",
         "5_year_follow_up_y_arm_1": "5-year follow-up"]
    
    let taskListSectionTitles = ["1-year follow-up tasks", "2-year follow-up tasks", "3-year follow-up tasks", "4-year follow-up tasks", "5-year follow-up tasks", "Start the task"]
    let taskListCellTitles =
        [["Delay Discounting", "Stroop (left button positive)", "Stroop (left button negative)"],
         ["Game of Dice (GoD)", "Little Man Task (LMT)", "Social Influence Task (SIT)"],
         ["Delay Discounting", "Math Task", "Stroop (left button positive)", "Stroop (left button negative)"],
         ["Little Man Task (LMT) -> Game of Dice -> BIRD","Game of Dice -> BIRD", "BIRD Only"],
         ["Stroop (LEFT NEGATIVE) -> Delay Discounting -> Math", "Stroop (LEFT POSITIVE) -> Delay Discounting -> Math", "Delay Discounting -> Math"],
         ["Start Inquisit Player"]]
    
    let taskDictionary =
        ["Delay Discounting": "adjustingdelaydiscounting%2Fadjustingdelaydiscounting_start.iqx",
         "Stroop (left button positive)": "emotionalstroop_lp%2Femotionalstroop_lp_start.iqx",
         "Stroop (left button negative)": "emotionalstroop_ln%2Femotionalstroop_ln_start.iqx",
         "Game of Dice (GoD)": "gameofdice%2Fgameofdicetask_start.iqx",
         "Little Man Task (LMT)": "littlemantest%2Flittlemantest_start.iqx",
         "Social Influence Task (SIT)": "socialinfluencetask%2Fsocialinfluencetask_start.iqx",
         "Math Task": "mathprotocol%2Fmathprotocol_start.iqx",
         "Little Man Task (LMT) -> Game of Dice -> BIRD": "remote_link",
         "Game of Dice -> BIRD": "remote_link",
         "BIRD Only": "remote_link",
         "Stroop (LEFT NEGATIVE) -> Delay Discounting -> Math": "remote_link",
         "Stroop (LEFT POSITIVE) -> Delay Discounting -> Math": "remote_link",
         "Delay Discounting -> Math": "remote_link",
         "TEST MATH": "remote_link"]

    var selectedTaskName: String?
    var selectedSession: String?
    var startTaskEnabled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (self.site == nil) {
            print("ERROR: MillisecondVC: viewDidLoad: site was not set.")
            return
        }
        if (self.pGUID == nil) {
            print("ERROR: MillisecondVC: viewDidLoad: pGUID was not set.")
            return
        }
        if (self.visit == nil) {
            print("ERROR: MillisecondVC: viewDidLoad: visit was not set.")
            return
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        for (taskName, iqxPath) in taskDictionary {
            print("taskDictionary: taskName: '\(taskName)' iqxPath: '\(iqxPath)'.")
        }
        
        switch visit {
        case "1_year_follow_up_y_arm_1":
            visitSectionIndex = 0
        case "2_year_follow_up_y_arm_1":
            visitSectionIndex = 1
        case "3_year_follow_up_y_arm_1":
            visitSectionIndex = 2
        case "4_year_follow_up_y_arm_1":
            visitSectionIndex = 3
        case "5_year_follow_up_y_arm_1":
            visitSectionIndex = 4
        default:
            print("ERROR: MillisecondVC: viewDidLoad: Invalid visit: \(String(describing: visit))")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("MillisecondVC: viewWillDisappear")
        if self.isMovingFromParent {
            print("MillisecondVC: isMovingFromParent")
            if (didEnterBackground) {
                self.delegate?.childVCDidSave(self, text: "")
            }
        }
    }
    
    var didEnterBackground = false
    func applicationDidEnterBackground() {
        print("MillisecondVC: applicationDidEnterBackground")
        didEnterBackground = true
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.infoTableView {
            return infoCellTitles.count
        } else {
            return taskListCellTitles.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.infoTableView {
            return infoCellTitles[section].count
        } else {
            // TODO: increment this value for each new visit
            if ((section == 5) || (section == visitSectionIndex)) {
                return taskListCellTitles[section].count
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == self.infoTableView {
            return infoSectionTitles[section]
        } else {
            // TODO: increment this value for each new visit
            if ((section == 5) || (section == visitSectionIndex)) {
                return taskListSectionTitles[section]
            } else {
                return nil
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.infoTableView {
            let identifier = "InfoCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            cell.textLabel!.text = infoCellTitles[indexPath.section][indexPath.row]
            //cell.detailTextLabel!.text = cellTitles[indexPath.row]
            
            if (indexPath.section == 0) {
                // Display the pGUID
                cell.textLabel!.text = pGUID
            }
            if (indexPath.section == 1) {
                // Display the visit
                if let visit = self.visit {
                    cell.textLabel!.text = visitDictionary[visit]
                }
            }
            
            if (indexPath.section == 2) {
                // Enable user interaction for selecting the session
                cell.selectionStyle = .default
                cell.isUserInteractionEnabled = true
            } else {
                cell.selectionStyle = .none
                cell.isUserInteractionEnabled = false
            }
            return cell
        } else {
            let identifier = "TaskListCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            cell.textLabel!.text = taskListCellTitles[indexPath.section][indexPath.row]
            
            // TODO: increment this value for each new visit
            if (indexPath.section == 5) {
                // Initialize and disable the Start Task button
                startTaskCell = cell
                startTaskCell.textLabel!.textAlignment = .center
                enableStartButton(enable: false)
            } else if (indexPath.section == visitSectionIndex) {
                // Enable user interaction for tasks at the current visit
                cell.textLabel!.textColor = nil
                cell.isUserInteractionEnabled = true
            } else {
                // Disable user interaction for tasks not at the current visit
                cell.textLabel!.textColor = UIColor.gray
                cell.isUserInteractionEnabled = false
            }
            //cell.detailTextLabel!.text = cellTitles[indexPath.row]
            //cell.selectionStyle = .none
            return cell
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    private func enableStartButton(enable: Bool) {
        startTaskEnabled = enable
        startTaskCell.textLabel!.textColor = enable ? view.tintColor : UIColor.gray
        startTaskCell.isUserInteractionEnabled = enable
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.infoTableView {
            print("MillisecondVC: didSelectRowAt: Info Table: Section: \(indexPath.section) Row: \(indexPath.row)")
            if (indexPath.section == 2) {
                // The user selected a session
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.accessoryType = .checkmark
                    selectedSession = "0\(indexPath.row+1)"
                    if ((selectedSession != nil) && (selectedTaskName != nil)) {
                        enableStartButton(enable: true)
                    }
                }
            }
        } else {
            // TODO: increment this value for each new visit
            if (indexPath.section == 5) {
                // The user pressed the start task button
                if (startTaskEnabled) {
                    startTask()
                }
            } else {
                print("MillisecondVC: didSelectRowAt: TaskList Table: Section: \(indexPath.section) Row: \(indexPath.row)")
                // The user selected a task
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.accessoryType = .checkmark
                    selectedTaskName = cell.textLabel!.text
                    if ((selectedSession != nil) && (selectedTaskName != nil)) {
                        enableStartButton(enable: true)
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView == self.infoTableView {
            if (indexPath.section == 2) {
                // Deselect a session
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.accessoryType = .none
                }
            }
        } else {
            // TODO: increment this value for each new visit
            if (indexPath.section < 5) {
                // Deselect a task
                if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
                    cell.accessoryType = .none
                }
            }
        }
    }
    
    private func startTask() {
        enableStartButton(enable: false)
        
        guard let site = self.site else {
            print("ERROR: site was not set.")
            return
        }
        guard let pGUID = self.pGUID else {
            print("ERROR: pGUID was not set.")
            return
        }
        guard let visit = self.visit else {
            print("ERROR: visit was not set.")
            return
        }
        guard let taskName = self.selectedTaskName else {
            print("ERROR: You did not select a task.")
            return
        }
        guard let iqxPath = taskDictionary[taskName] else {
            print("ERROR: Could not find iqxPath for task name: \(taskName)")
            return
        }
        guard let session = self.selectedSession else {
            print("ERROR: You did not select a session.")
            return
        }
        
        let urlPrefix = "SECRET_MILLISECOND_URL_PREFIX_HERE"
        let urlSuffix = "SECRET_MILLISECOND_URL_SUFFIX_HERE"
        
        var urlString: String
        if (taskName == "TEST MATH") {
            urlString = "https://SECRET_MILLISECOND_URL_HERE?site=\(site)&subjectid=\(pGUID)%20\(visit)%20\(session)&groupid=4"
        } else if (taskName == "Little Man Task (LMT) -> Game of Dice -> BIRD") {
            urlString = "https://SECRET_MILLISECOND_URL_HERE?site=\(site)&subjectid=\(pGUID)%20\(visit)%20\(session)&groupid=1"
        } else if (taskName == "Game of Dice -> BIRD") {
            urlString = "https://SECRET_MILLISECOND_URL_HERE?site=\(site)&subjectid=\(pGUID)%20\(visit)%20\(session)&groupid=2"
        } else if (taskName == "BIRD Only") {
            urlString = "https://SECRET_MILLISECOND_URL_HERE?site=\(site)&subjectid=\(pGUID)%20\(visit)%20\(session)&groupid=3"
        } else if (taskName == "Stroop (LEFT NEGATIVE) -> Delay Discounting -> Math") {
            urlString = "https://SECRET_MILLISECOND_URL_HERE?site=\(site)&subjectid=\(pGUID)%20\(visit)%20\(session)&groupid=1"
        } else if (taskName == "Stroop (LEFT POSITIVE) -> Delay Discounting -> Math") {
            urlString = "https://SECRET_MILLISECOND_URL_HERE?site=\(site)&subjectid=\(pGUID)%20\(visit)%20\(session)&groupid=2"
        } else if (taskName == "Delay Discounting -> Math") {
            urlString = "https://SECRET_MILLISECOND_URL_HERE?site=\(site)&subjectid=\(pGUID)%20\(visit)%20\(session)&groupid=3"
        } else {
            urlString = "\(urlPrefix)\(iqxPath)&AccountName=SECRET_ACCOUNT_NAME_HERE&GroupId=\(site)&SubjectId=\(pGUID)%20\(visit)%20\(session)\(urlSuffix)"
        }
        let message = "'\(taskName)'\nVisit: \(visit)\nSession: \(session)"
        self.presentAlertWithTitle(title: "Is this correct?", message: message, options: ["Yes", "No"]) { (option) in
            print("option: \(option)")
            switch(option) {
            case 0:
                print("Open Iquisit Player: \(urlString)")
                UIApplication.shared.open(NSURL(string:urlString)! as URL)
                break
            case 1:
                print("The RA did not confirm.")
                break
            default:
                break
            }
        }
    }
}

