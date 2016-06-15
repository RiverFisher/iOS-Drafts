//
//  OrdersController.swift
//  booking_ios
//
//  Created by MacBook Pro on 18.11.15.
//  Copyright © 2015 MacBook Pro. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import RealmSwift
import FontAwesome_swift
import Google_Material_Design_Icons_Swift

class OrdersTestController: UITableViewController {
    @IBOutlet weak var segueToLeftOutMenuButton: UIBarButtonItem!
    
    var userID: Int?
    
    var businessTripsRepository: JSON = [: ]
    var businessTripsSectionsState: [Int: Bool] = [: ]
    
    var orders: JSON = [: ]
    var services: [Int] = []
    var ordersState: [Int: Bool] = [: ]
    
    let aa = true
    
    var lastTappingInfo: (expanded: Bool, tappedSectionNumber: Int, tappedRowNumber: Int, subrowsCount: Int) = (true, 0, 0, 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "FoggyCity")!)
        
        //let realm = try! Realm()
        
        //let orders = realm.objects(Order)
        //print("My orders are \(orders)")
        
        userID = 1
        getAllUserOrders()
        
        // MARK: - Navigation buttons
        segueToLeftOutMenuButton.target = self.revealViewController()
        segueToLeftOutMenuButton.action = Selector("revealToggle:")
        //segueToLeftOutMenuButton.GMDIcon = GMDType.GMDMenu
        segueToLeftOutMenuButton.setGMDIcon(GMDType.GMDMenu, iconSize: 30)
        segueToLeftOutMenuButton.tintColor = UIColor(rgb: 0x757575)
        if revealViewController() != nil {
            self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /**
     *  SECTION OF METHODS: - Methods for exchange with API
     */
    
    // orders = [orderID] = { "Командировка", 123574079, "Новая" }
    //                   [serviceID] = { "Гостиница", Дата с , Дата по , Создано , Стоимость , "Отклонено" }
    //                              [internalService] = { "Ужин в гостинице", 3580 RUB }
    
    func getAllUserOrders() -> () {
        let URLRequest = RaketaNewAPI.Router.GetOrdersByUserID(userID!).URLRequest
        Alamofire.request(URLRequest).responseJSON { response in
            
            let result = response.result
            
            switch result {
            case .Success:
                if let value = result.value {
                    
                    for (orderIndex, orderValue): (String, JSON) in JSON(value)["result"] {
                        
                        //print("\(orderIndex): order №\(orderNumber), services are: \(orderValue["services"])")
                        
                        self.orders[orderIndex] = [: ]
                        self.orders[orderIndex]["info"] = [: ]
                        self.orders[orderIndex]["info"]["id"] = orderValue["id"]
                        self.orders[orderIndex]["info"]["Тип"] = orderValue["type"]
                        self.orders[orderIndex]["info"]["Дата создания"] = self.getCreationDate(orderValue["created"])
                        self.orders[orderIndex]["info"]["Статус"] = orderValue["status"]
                        if orderValue["services"].count != 0 {
                            self.orders[orderIndex]["services"] = [: ]
                            for (_, serviceValue): (String, JSON) in orderValue["services"] {
                                let serviceID = serviceValue.intValue
                                let serviceKey = serviceValue.stringValue
                                
                                self.services.append(serviceID)
                                
                                self.orders[orderIndex]["services"][serviceKey] = [: ]
                                self.orders[orderIndex]["services"][serviceKey]["info"] = [: ]
                                
                                self.getServiceByID(serviceID)
                            }
                        }
                    }
                }
                else { print("JSON data is nil.") }
            case .Failure: break
            }
            
            print(self.orders)
            
            self.tableView.reloadData()
        }
    }
    
    func getServiceByID(serviceID: Int) -> () {
        let serviceKey = String(serviceID)
        //var variableToResult: JSON = [: ]
        
        let URLRequest = RaketaNewAPI.Router.GetServiceByID(serviceID).URLRequest
        Alamofire.request(URLRequest).responseJSON { response in
            
            let result = response.result
            
            switch result {
            case .Success:
                if let value = result.value {
                    let orderValue = JSON(value)["result"]
                    let orderIndex = orderValue["order"].stringValue
                    
                    self.orders[orderIndex]["services"][serviceKey]["info"]["id"] = orderValue["id"]
                    self.orders[orderIndex]["services"][serviceKey]["info"]["Тип"] = orderValue["type"]
                    self.orders[orderIndex]["services"][serviceKey]["info"]["Дата создания"] = self.getCreationDate(orderValue["created"])
                    self.orders[orderIndex]["services"][serviceKey]["info"]["Период действия"] = self.getServicePeriod(value["start"], endDate: orderValue["stop"])
                    self.orders[orderIndex]["services"][serviceKey]["info"]["Статус"] = orderValue["status"]
                    self.orders[orderIndex]["services"][serviceKey]["info"]["Стоимость"] = self.getFullAmount(orderValue["amount"], currency: orderValue["currency"])
                    
                    if serviceKey == "6" {
                        print("AAAAAAAAAA")
                        print(value)
                    }
                    
                    if orderValue["extendData"]["services"].count != 0 {
                        print("AAAAAAAAAAAAAAAAAAAAAAA")
                        self.orders[orderIndex]["services"][serviceKey]["internalServices"] = [: ]
//                        for (internalServiceIndex, internalServiceValue): (String, JSON) in value["extendData"]["services"] {
//                            self.orders[orderIndex]["services"][serviceKey]["internalServices"][internalServiceIndex] = [: ]
//                            self.orders[orderIndex]["services"][serviceKey]["internalServices"][internalServiceIndex]["Наименование услуги"] = internalServiceValue["name"]
//                            self.orders[orderIndex]["services"][serviceKey]["internalServices"][internalServiceIndex]["Стоимость услуги"] = internalServiceValue["price"]
//                        }
                    }
                }
                else { print("JSON data is nil.") }
            case .Failure: break;
            }
        }
    }
    
    func getServiceByIDJSON(serviceID: Int) -> JSON {
        var variableToResult: JSON = [: ]
        
        let URLRequest = RaketaNewAPI.Router.GetServiceByID(serviceID).URLRequest
        Alamofire.request(URLRequest).responseJSON { response in
            
            let result = response.result
            
            switch result {
            case .Success:
                if let value = result.value {
                    variableToResult = JSON(value)["result"]
                }
                else { print("JSON data is nil.") }
            case .Failure: break;
            }
        }
        
        return variableToResult
    }
    
    /**
     *  SECTION OF METHODS: - Supporting methods
     */
    
    func constructNameForSectionHeadRow(indexPath: NSIndexPath) -> String {
        //        let numberToString = self.businessTripsRepository[String(indexPath.section)]["0"].stringValue
        //        let countOfServices = String(self.businessTripsRepository[String(indexPath.section)].count - 1)
        //        return "Командировка №" + numberToString + " (всего услуг: " + countOfServices + ")"
        var creationDate: String {
            let formatter = NSDateFormatter()
            /**
            *  MARK: - Specifying of the settings for NSDateFormatter() to prepare it for transformation of the date from UNIX TIMESTAMP to custom format
            *          Locale identifier must be "ru-RU" for russian translation and both "en-US" and "en_US_POSIX" for US translation
            *          For specifying of the time zone uncomment next snippet of code:
            *              formatter.timeZone = NSTimeZone.localTimeZone()
            */
            formatter.locale = NSLocale(localeIdentifier: "ru-RU")
            formatter.dateFormat = "d MMM yyyy (hh:mm)"
            
            let creationDate = NSDate(timeIntervalSince1970: self.businessTripsRepository[String(indexPath.section)]["0"]["creationDate"].doubleValue)
            
            return formatter.stringFromDate(creationDate)
        }
        //return "\(self.businessTripsRepository[String(indexPath.section)]["0"]["id"].intValue), \(creationDate) (\(String(self.businessTripsRepository[String(indexPath.section)].count - 1)) услуг)"
        return "Встреча с представителями Sony [\(String(self.businessTripsRepository[String(indexPath.section)].count - 1))]"
    }
    
    func constructNameForRowWithService(indexPath: NSIndexPath) -> String {
        let numberToString = self.businessTripsRepository[String(indexPath.section)][String(indexPath.row)].stringValue
        //let type = self.businessTripsRepository[String(indexPath.section)][String(indexPath.row)]["type"].stringValue
        //let createdAt = self.businessTripsRepository[String(indexPath.section)][String(indexPath.row)]["main"]["date"].stringValue
        //return "   №" + numberToString + " (" + type + ")" + ", " + createdAt
        return "    №\(numberToString)"
    }
    
    func getCreationDate(creationDate: JSON) -> JSON {
        let formatter = NSDateFormatter()
        /**
         *  MARK: - Specifying of the settings for NSDateFormatter() to prepare it for transformation of the date from UNIX TIMESTAMP to custom format
         *          Locale identifier must be "ru-RU" for russian translation and both "en-US" and "en_US_POSIX" for US translation
         *          For specifying of the time zone uncomment next snippet of code:
         *              formatter.timeZone = NSTimeZone.localTimeZone()
         */
        formatter.locale = NSLocale(localeIdentifier: "ru-RU")
        formatter.dateFormat = "d MMM yyyy (hh:mm)"
        
        let creationDate = NSDate(timeIntervalSince1970: creationDate.doubleValue)
        
        return JSON(formatter.stringFromDate(creationDate))
    }
    
    func getServicePeriod(beginningDate: JSON, endDate: JSON) -> JSON {
        let formatter = NSDateFormatter()
        /**
         *  MARK: - Specifying of the settings for NSDateFormatter() to prepare it for transformation of the date from UNIX TIMESTAMP to custom format
         *          Locale identifier must be "ru-RU" for russian translation and both "en-US" and "en_US_POSIX" for US translation
         *          For specifying of the time zone uncomment next snippet of code:
         *              formatter.timeZone = NSTimeZone.localTimeZone()
         */
        formatter.locale = NSLocale(localeIdentifier: "ru-RU")
        formatter.dateFormat = "d MMM yyyy (hh:mm)"
        
        let beginningDate = NSDate(timeIntervalSince1970: beginningDate.doubleValue)
        let endDate = NSDate(timeIntervalSince1970: endDate.doubleValue)
        
        return JSON("\(formatter.stringFromDate(beginningDate)) - \(formatter.stringFromDate(endDate))")
    }
    
    func getFullAmount(amount: JSON, currency: JSON) -> JSON {
        let amount = amount.stringValue
        let currency = currency.stringValue
        return JSON("\(amount) \(currency)")
    }
    
    func getHeadlineForService(section: Int, row: Int) -> String {
        var type: String {
            switch orders[section]["services"][row]["info"]["Тип"] {
            case "hotel": return "Отель"
            default: return "Место проживания"
            }
        }
        let id = orders[section]["services"][row]["info"]["id"]
        return "\(type) \(id)"
    }
    
    func getHeadlineForOrder(section: Int, row: Int) -> String {
        let internalServiceIndex = row - lastTappingInfo.tappedRowNumber
        let name = orders[section]["services"][lastTappingInfo.tappedRowNumber]["internalServices"][internalServiceIndex]["Наименование услуги"].stringValue
        return name
    }
    
    func getMainContentForOrder(section: Int, row: Int) -> String {
        let internalServiceIndex = row - lastTappingInfo.tappedRowNumber
        let name = orders[section]["services"][lastTappingInfo.tappedRowNumber]["internalServices"][internalServiceIndex]["Стоимость"].stringValue
        return name
    }
    
//    func getDetailsForService(section: Int, row: Int) -> String {
//        var type: String {
//            switch orders[section]["services"][row]["info"]["Тип"] {
//            case "hotel": return "Отель"
//            default: return "Место проживания"
//            }
//        }
//        let id = orders[section]["services"][row]["info"]["id"]
//        return "\(type) \(id)"
//    }
    
    /**
     *  SECTION OF METHODS: - UITableView methods
     */
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.orders.count
    }
    
    // Может быть всё-таки убрать if-else? По-моему здесь всегда @#$.count будет возвращать хотя бы 1.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if lastTappingInfo.expanded && lastTappingInfo.tappedSectionNumber == section { return orders[section]["services"].count + lastTappingInfo.subrowsCount }
        else { return orders[section]["services"].count }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let id = self.orders[section]["info"]["id"].stringValue
        let creationDate = self.orders[section]["info"]["Дата создания"].stringValue
        var type: String {
            switch self.orders[section]["info"]["Тип"].stringValue {
            case "trip": return "Командировка"
            case "event": return "Событие"
            case "simple": return "Простой заказ"
            default: return ""
            }
        }
        let status = self.orders[section]["info"]["Статус"].stringValue
        return "\(type) №\(id) от \(creationDate) (\(status))"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if lastTappingInfo.expanded && indexPath.section == lastTappingInfo.tappedSectionNumber && indexPath.row > lastTappingInfo.tappedRowNumber && indexPath.row <= lastTappingInfo.tappedRowNumber + lastTappingInfo.subrowsCount {
            let serviceCell = self.tableView.dequeueReusableCellWithIdentifier("serviceCell") as! ServiceCell
            
            serviceCell.servicePictographLabel.GMDIcon = GMDType.GMDShoppingCart
            serviceCell.servicePictographLabel.font = serviceCell.servicePictographLabel.font.fontWithSize(24)
            serviceCell.servicePictographLabel.textColor = UIColor(rgb: 0x757575)
            
            serviceCell.serviceTestHeadlineLabel.text = self.getHeadlineForOrder(indexPath.section, row: indexPath.row)
            serviceCell.serviceTestMainContentLabel.text = self.getMainContentForOrder(indexPath.section, row: indexPath.row)
            
            serviceCell.backgroundColor = UIColor.clearColor()
            
            return serviceCell
        }
        else {
            let orderCell = self.tableView.dequeueReusableCellWithIdentifier("orderCell") as! OrderCell
            
            orderCell.orderPictographLabel.GMDIcon = GMDType.GMDLocationCity
            orderCell.orderPictographLabel.font = orderCell.orderPictographLabel.font.fontWithSize(30)
            orderCell.orderPictographLabel.textColor = UIColor(rgb: 0x757575)
            
            orderCell.orderTestHeadlineLabel.text = self.getHeadlineForService(indexPath.section, row: indexPath.row)
            orderCell.orderTestMainContent.text = orders[indexPath.section]["services"][indexPath.row]["info"]["Период действия"].stringValue
            //orderCell.orderTestStatusLabel.text = "New"
            
            orderCell.backgroundColor = UIColor.clearColor()//.backgroundImage("OrderCellBackgroundLineMini")
            
            return orderCell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if lastTappingInfo.expanded {
            if lastTappingInfo.tappedSectionNumber == indexPath.section && lastTappingInfo.tappedRowNumber == indexPath.row {
                lastTappingInfo.expanded = false
                lastTappingInfo.subrowsCount =  0
            }
            else {
                lastTappingInfo.subrowsCount = orders[indexPath.section]["services"][indexPath.row]["internalServices"].count
            }
        }
        
        //let a = orders[indexPath.section]["services"][indexPath.row]
        
        if !orders[indexPath.section]["services"][indexPath.row].isExists() {
            self.performSegueWithIdentifier("segueToServiceDetails", sender: self)
        }
        
        //self.tableView.reloadRowsAtIndexPaths(indexPath, withRowAnimation: UITableViewRowAnimation.Fade)
        
        self.tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    /**
     *  SECTION OF METHODS: - Methods for navigation
     */
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "segueToServiceDetails") {
            let destinationViewController: ServiceDetailsController = segue.destinationViewController as! ServiceDetailsController
            let indexPath = tableView.indexPathForSelectedRow
            destinationViewController.serviceID = businessTripsRepository[String(indexPath!.section)][String(indexPath!.row)].string
        }
    }
}
