import UIKit
import Alamofire
import SwiftyJSON

class BusinessTripsController: UITableViewController {
    
    @IBOutlet weak var leftOutMenuButton: UIBarButtonItem!
    
    var businessTripsRepository: JSON = [: ]
    var businessTripsSectionsState = Dictionary<Int, Bool>()
    
    //var chatInfo: JSON = [: ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getAllUserOrders()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /**
     *  SECTION OF METHODS: - Methods for exchange with API
     */
    
    func getAllUserOrders() -> () {
        let URLRequest = Router.Router.GetAllUserOrders().URLRequest
        Alamofire.request(URLRequest).responseJSON { response in
            
            let result = response.result
            
            switch result {
            case .Success:
                if let value = result.value {
                    
                    let JSONValue = JSON(value)
                    for (_, subJSON): (String, JSON) in JSONValue {
                        let tripNumberOfCurrentService = subJSON["main"]["order"].stringValue
                        
                        let existingBusinessTripNumber = self.businessTripForServiceIsExist(tripNumberOfCurrentService, repository: self.businessTripsRepository).stringNumberOfBusinessTrip
                        if existingBusinessTripNumber != nil {
                            var countOfChilds = self.businessTripsRepository[existingBusinessTripNumber!].count
                            
                            if countOfChilds == 1 {
                                self.businessTripsRepository[existingBusinessTripNumber!]["1"] = self.businessTripsRepository[existingBusinessTripNumber!]["0"]
                                self.businessTripsRepository[existingBusinessTripNumber!]["0"] = nil
                                countOfChilds++
                            }
                            
                            self.businessTripsRepository[existingBusinessTripNumber!][String(countOfChilds)] = subJSON
                        }
                        else {
                            let countOfElementsInRepository = self.businessTripsRepository.count
                            self.businessTripsRepository[String(countOfElementsInRepository)] = JSON(["0": JSON([: ])])
                            self.businessTripsRepository[String(countOfElementsInRepository)]["0"] = subJSON
                            
                            /**
                             *  At once add necessary key to the dictionary with sections states (starting initialization of the widget)
                             */
                            self.businessTripsSectionsState[countOfElementsInRepository] = false
                            
                            /**
                             *  Add info to chatInfo
                             */
                            //self.chatInfo[String(countOfElementsInRepository)] = JSON(["0": JSON([])])
                            //self.chatInfo[String(countOfElementsInRepository)]["0"] = JSON(["id": subJSON["external"]["id"], "mid": subJSON["external"][]])
                        }
                    }
                }
                else { print("JSON data is nil.") }
            case .Failure: break
            }
            
            self.tableView.reloadData()
        }
    }
    
    /**
     *  SECTION OF METHODS: - Supporting methods
     */
    
    func businessTripForServiceIsExist(businessTripIDForCheckingCondition: String, repository: JSON) -> (Bool, stringNumberOfBusinessTrip: String?) {
        for (businessTripID__keyInJSON, businessTripWithServices): (String, JSON) in repository {
            /*// MARK: - For debugging
            businessTripWithServices["0"]["main"]["order"] != nil ? print("ID of the current business trip in the current repository -> \(businessTripWithServices["0"]["main"]["order"].stringValue)") : print("ID of the current business trip in the current repository -> \(businessTripWithServices["1"]["main"]["order"].stringValue)")
            print("Business trip ID for checking the condition -> \(businessTripIDForCheckingCondition)")
            // END OF MARK*/
            if businessTripWithServices["0"]["main"]["order"].stringValue == businessTripIDForCheckingCondition || businessTripWithServices["1"]["main"]["order"].stringValue == businessTripIDForCheckingCondition {
                return (true, businessTripID__keyInJSON)
            }
        }
        return (false, nil)
    }
    
    func getCellDescriptorForIndexPath(indexPath: NSIndexPath) -> String {
        if indexPath.row == 0 && self.businessTripsRepository[String(indexPath.section)].count != 1 {
            return "businessTripCell"
        }
        else {
            return "serviceInBusinessTripCell"
        }
    }
    
    func constructNameForSectionHeadRow(indexPath: NSIndexPath) -> String {
        let numberToString = self.businessTripsRepository[String(indexPath.section)]["1"]["main"]["order"].stringValue
        let countOfServices = String(self.businessTripsRepository[String(indexPath.section)].count - 1)
        return "Командировка №" + numberToString + " (всего услуг: " + countOfServices + ")"
    }
    
    func constructNameForRowWithService(indexPath: NSIndexPath) -> String {
        let numberToString = self.businessTripsRepository[String(indexPath.section)][String(indexPath.row)]["main"]["id"].stringValue
        let type = self.businessTripsRepository[String(indexPath.section)][String(indexPath.row)]["type"].stringValue
        let createdAt = self.businessTripsRepository[String(indexPath.section)][String(indexPath.row)]["main"]["date"].stringValue
        return "   №" + numberToString + " (" + type + ")" + ", " + createdAt
    }
    
    /**
     *  SECTION OF METHODS: - UITableView methods
     */
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.businessTripsRepository != nil {
            return self.businessTripsRepository.count
        }
        else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.businessTripsSectionsState[section] == true { return self.businessTripsRepository[String(section)].count }
        else { return 1 }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currentCellDescriptor = getCellDescriptorForIndexPath(indexPath)
        let cell = self.tableView.dequeueReusableCellWithIdentifier(currentCellDescriptor, forIndexPath: indexPath) as! BusinessTripsCell
        
        cell.textLabel!.text = currentCellDescriptor == "businessTripCell" ? constructNameForSectionHeadRow(indexPath) : constructNameForRowWithService(indexPath)
        
        //cell.backgroundColor = indexPath.row % 2 == 0 ? UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) : UIColor.whiteColor()
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let stateOfRowsBeforeTapping: Bool = self.businessTripsSectionsState[indexPath.section]!
        self.businessTripsSectionsState[indexPath.section] = !stateOfRowsBeforeTapping
        
        if !(indexPath.row == 0 && self.businessTripsRepository[String(indexPath.section)].count != 1) {
            self.performSegueWithIdentifier("segueToServiceDetails", sender: self)
        }
        
        self.tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Fade)
    }
}
