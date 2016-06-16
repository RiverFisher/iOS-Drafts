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
    var services: JSON = [: ]
    var ordersServices: [Int: [Int]] = [:]
    var ordersState: [Int: Bool] = [: ]
    
    var lastTappingInfo: (expanded: Bool, tappedSectionNumber: Int, tappedRowNumber: Int, subrowsCount: Int) = (true, 0, 0, 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "FoggyCity")!)
        
        //let realm = try! Realm()
        
        //let orders = realm.objects(Order)
        //print("My orders are \(orders)")
        
        userID = 1
        self.getAllUserOrders()
        //sleep(5)
        //print(orders)
        
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
    func getAllUserOrders() -> () {
        let URLRequest = RaketaNewAPI.Router.GetOrdersByUserID(userID!).URLRequest
        Alamofire.request(URLRequest).responseJSON { response in
            
            let result = response.result
            
            switch result {
            case .Success:
                if let value = result.value {
                    
                    for (orderIndex, orderValue): (String, JSON) in JSON(value)["result"] {
                        let currentOrderID = orderValue["id"].intValue
                        
                        let currentInfo: JSON = [
                            "id": orderValue["id"].stringValue,
                            "Тип": orderValue["type"].stringValue,
                            "Дата создания": self.getCreationDate(orderValue["created"]).stringValue,
                            "Статус": orderValue["status"].stringValue
                        ]
                        let currentOrder: JSON = ["info": currentInfo.object]
                        
                        self.orders[orderIndex] = [: ]
                        self.orders[orderIndex]["info"] = currentInfo
                        self.orders[orderIndex]["services"] = [: ]
                        
                        self.getServicesByOrderIDJSON(currentOrderID, orderIndex: orderIndex)
                        
                        //print(orderServices)
                    }
                }
                else { print("JSON data is nil.") }
            case .Failure: break
            }
            
            print(self.orders)
            
            self.tableView.reloadData()
        }
    }
    
    func getServicesByOrderIDJSON(orderID: Int, orderIndex: String) -> () {
        let URLRequest = RaketaNewAPI.Router.GetServicesByOrderID(orderID).URLRequest
        Alamofire.request(URLRequest).responseJSON { response in
            
            let result = response.result
            
            switch result {
            case .Success:
                if let value = result.value {
                    for (serviceIndex, serviceValue): (String, JSON) in JSON(value)["result"] {
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["id"] = serviceValue["id"]
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["Тип"] = serviceValue["type"]
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["Дата создания"] = self.getCreationDate(serviceValue["created"])
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["Период действия"] = self.getServicePeriod(serviceValue["start"], endDate: serviceValue["stop"])
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["Статус"] = serviceValue["status"]
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["Стоимость"] = self.getFullAmount(serviceValue["amount"], currency: serviceValue["currency"])
                        
                        if serviceValue["extendData"]["services"].count != 0 {
                            self.orders[orderIndex]["services"][serviceIndex]["internalServices"] = [: ]
                            for (internalServiceIndex, internalServiceValue): (String, JSON) in serviceValue["extendData"]["services"] {
                                self.orders[orderIndex]["services"][serviceIndex]["internalServices"][internalServiceIndex] = [: ]
                                self.orders[orderIndex]["services"][serviceIndex]["internalServices"][internalServiceIndex]["Наименование услуги"] = internalServiceValue["name"]
                                self.orders[orderIndex]["services"][serviceIndex]["internalServices"][internalServiceIndex]["Стоимость услуги"] = internalServiceValue["price"]
                            }
                        }
                    }
                }
                else { print("JSON data is nil.") }
            case .Failure: break
            }
        }
    }
    
    func getServicesByOrderID(orderID: Int) -> () {
        let URLRequest = RaketaNewAPI.Router.GetServicesByOrderID(orderID).URLRequest
        Alamofire.request(URLRequest).responseJSON { response in
            
            let result = response.result
            
            switch result {
            case .Success:
                if let value = result.value {
                    for (_, serviceValue): (String, JSON) in JSON(value)["result"] {
                        let orderIndex = serviceValue["order"].stringValue
                        let serviceIndex = serviceValue["id"].stringValue
                        
                        //                        self.orders[orderIndex]["services"][serviceIndex] = [: ]
                        //                        self.orders[orderIndex]["services"][serviceIndex]["info"] = [: ]
                        
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["id"] = serviceValue["id"]
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["Тип"] = serviceValue["type"]
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["Дата создания"] = self.getCreationDate(serviceValue["created"])
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["Период действия"] = self.getServicePeriod(serviceValue["start"], endDate: serviceValue["stop"])
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["Статус"] = serviceValue["status"]
                        self.orders[orderIndex]["services"][serviceIndex]["info"]["Стоимость"] = self.getFullAmount(serviceValue["amount"], currency: serviceValue["currency"])
                        
                        //print(self.orders[orderIndex]["services"])
                        
                        
                        //                        }
                        
                        if serviceValue["extendData"]["services"].count != 0 {
                            //print("AAAAAAAAAAAAAAAAAAAAAAA")
                            self.orders[orderIndex]["services"][serviceIndex]["internalServices"] = [: ]
                            for (internalServiceIndex, internalServiceValue): (String, JSON) in serviceValue["extendData"]["services"] {
                                self.orders[orderIndex]["services"][serviceIndex]["internalServices"][internalServiceIndex] = [: ]
                                self.orders[orderIndex]["services"][serviceIndex]["internalServices"][internalServiceIndex]["Наименование услуги"] = internalServiceValue["name"]
                                self.orders[orderIndex]["services"][serviceIndex]["internalServices"][internalServiceIndex]["Стоимость услуги"] = internalServiceValue["price"]
                            }
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
            switch orders[String(section)]["services"][String(row)]["info"]["Тип"] {
            case "hotel": return "Отель"
            default: return "Место проживания"
            }
        }
        let id = orders[String(section)]["services"][String(row)]["info"]["id"]
        return "\(type) \(id)"
    }
    
    func getHeadlineForOrder(section: Int, row: Int) -> String {
        let internalServiceIndex = row// - lastTappingInfo.tappedRowNumber
        let name = orders[String(section)]["services"][lastTappingInfo.tappedRowNumber]["internalServices"][String(internalServiceIndex)]["Наименование услуги"].stringValue
        return name
    }
    
    func getMainContentForOrder(section: Int, row: Int) -> String {
        let internalServiceIndex = row - lastTappingInfo.tappedRowNumber
        let name = orders[String(section)]["services"][lastTappingInfo.tappedRowNumber]["internalServices"][String(internalServiceIndex)]["Стоимость"].stringValue
        return name
    }
    
    /**
     *  SECTION OF METHODS: - UITableView methods
     */
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return orders.count
    }
    
    // Может быть всё-таки убрать if-else? По-моему здесь всегда @#$.count будет возвращать хотя бы 1.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //        if lastTappingInfo.expanded && lastTappingInfo.tappedSectionNumber == section { return orders[section]["services"].count + lastTappingInfo.subrowsCount }
        //        else { return orders[section]["services"].count }
        
        return orders[String(section)]["services"].count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let id = orders[String(section)]["info"]["id"].stringValue
        let creationDate = orders[String(section)]["info"]["Дата создания"].stringValue
        var type: String {
            switch orders[String(section)]["info"]["Тип"].stringValue {
            case "trip": return "Заказ"
            case "event": return "Событие"
            case "simple": return "Простой заказ"
            default: return ""
            }
        }
        var status: String {
            switch orders[String(section)]["info"]["Статус"].stringValue {
            case "new": return "Новый"
            case "cancelled": return "Закрыто"
            case "completed": return "Выполнено"
            default: return ""
            }
        }
        
        //return "\(type) №\(id) от \(creationDate) (\(status))"
        return "\(type) от \(creationDate) (\(status))"
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //        if let view = view as? UITableViewHeaderFooterView {
        //            view.backgroundView?.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
        //            view.textLabel!.backgroundColor = UIColor.clearColor()
        //            view.textLabel!.textColor = UIColor.whiteColor()
        //            view.textLabel!.font = UIFont.boldSystemFontOfSize(15)
        //        }
        
        let view: UITableViewHeaderFooterView = UITableViewHeaderFooterView()
        view.backgroundView?.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
        view.textLabel?.backgroundColor = UIColor.clearColor()
        view.textLabel!.font = UIFont.systemFontOfSize(11)
        
        return view
    }
    
    //    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    //
    //        view.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
    //
    //        let sectionTitle: String = self.tableView(tableView, titleForHeaderInSection: section)!
    //
    //        let title: UILabel = UILabel()
    //
    //        title.text = sectionTitle
    //        title.textColor = UIColor(red: 0.0, green: 0.54, blue: 0.0, alpha: 0.8)
    //        title.backgroundColor = UIColor.clearColor()
    //        title.font = UIFont.boldSystemFontOfSize(11)
    //    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //        if lastTappingInfo.expanded && indexPath.section == lastTappingInfo.tappedSectionNumber && indexPath.row > lastTappingInfo.tappedRowNumber && indexPath.row <= lastTappingInfo.tappedRowNumber + lastTappingInfo.subrowsCount {
        //            let serviceCell = self.tableView.dequeueReusableCellWithIdentifier("serviceCell") as! ServiceCell
        //
        //            serviceCell.servicePictographLabel.GMDIcon = GMDType.GMDShoppingCart
        //            serviceCell.servicePictographLabel.font = serviceCell.servicePictographLabel.font.fontWithSize(24)
        //            serviceCell.servicePictographLabel.textColor = UIColor(rgb: 0x757575)
        //
        //            serviceCell.serviceTestHeadlineLabel.text = self.getHeadlineForOrder(indexPath.section, row: indexPath.row)
        //            serviceCell.serviceTestMainContentLabel.text = self.getMainContentForOrder(indexPath.section, row: indexPath.row)
        //
        //            serviceCell.backgroundColor = UIColor.clearColor()
        //            serviceCell.backgroundColor = UIColor.whiteColor()
        //
        //            return serviceCell
        //        }
        //        else {
        //            let orderCell = self.tableView.dequeueReusableCellWithIdentifier("orderCell") as! OrderCell
        //
        //            orderCell.orderPictographLabel.GMDIcon = GMDType.GMDLocationCity
        //            orderCell.orderPictographLabel.font = orderCell.orderPictographLabel.font.fontWithSize(30)
        //            orderCell.orderPictographLabel.textColor = UIColor(rgb: 0x757575)
        //
        //            orderCell.orderTestHeadlineLabel.text = self.getHeadlineForService(indexPath.section, row: indexPath.row)
        //            orderCell.orderTestMainContent.text = orders[String(indexPath.section)]["services"][String(indexPath.row)]["info"]["Период действия"].stringValue
        //            //orderCell.orderTestStatusLabel.text = "New"
        //
        //            orderCell.backgroundColor = UIColor.clearColor()//.backgroundImage("OrderCellBackgroundLineMini")
        //            orderCell.backgroundColor = UIColor.whiteColor()
        //
        //            return orderCell
        //        }
        let orderCell = self.tableView.dequeueReusableCellWithIdentifier("orderCell") as! OrderCell
        
        orderCell.orderPictographLabel.GMDIcon = GMDType.GMDLocationCity
        orderCell.orderPictographLabel.font = orderCell.orderPictographLabel.font.fontWithSize(30)
        orderCell.orderPictographLabel.textColor = UIColor(rgb: 0x757575)
        
        orderCell.orderTestHeadlineLabel.text = self.getHeadlineForService(indexPath.section, row: indexPath.row)
        orderCell.orderTestMainContent.text = orders[String(indexPath.section)]["services"][String(indexPath.row)]["info"]["Период действия"].stringValue
        //orderCell.orderTestStatusLabel.text = "New"
        
        orderCell.backgroundColor = UIColor.clearColor()//.backgroundImage("OrderCellBackgroundLineMini")
        orderCell.backgroundColor = UIColor.whiteColor()
        
        return orderCell
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
