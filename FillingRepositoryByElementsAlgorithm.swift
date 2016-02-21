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
}
