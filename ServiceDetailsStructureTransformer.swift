import Foundation
import SwiftyJSON

class ServiceDetailsStructureTransformer {
    
    private var mainServiceDetails: JSON = []
    private var externalServiceDetails: JSON = []
    //internal var transformedServiceDetails: [[Int: JSON]] = []
    
    required init(mainServiceDetails: JSON, externalServiceDetails: JSON) {
        self.mainServiceDetails = mainServiceDetails
        self.externalServiceDetails = externalServiceDetails
    }
    
    func transformServiceDetailsStructure() -> [[Int: JSON]] {
        var transformedServiceDetails: [[Int: JSON]] = []
        
        let type = externalServiceDetails["type"].stringValue
        
        switch type {
        case "hotel":
            var stay: String {
                let formatter = NSDateFormatter()
                
                /**
                *  MARK: - Specifying of the settings for NSDateFormatter() to parser was able to recognize the date.
                *          Locale identifier must be "ru-RU" for russian translation and both "en-US" and "en_US_POSIX" for US translation.
                *          For specifying of the time zone uncomment next snippet of code. // formatter.timeZone = NSTimeZone.localTimeZone()
                */
                formatter.locale = NSLocale(localeIdentifier: "ru-RU")
                formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                
                let startDate = formatter.dateFromString(externalServiceDetails["start_date"].stringValue)
                let endDate = formatter.dateFromString(externalServiceDetails["end_date"].stringValue)
                
                /**
                *  MARK: - Changing of the settings for NSDateFormatter() to prepare it for transformation of the date to another format.
                */
                formatter.dateFormat = "d MMM yyyy (hh:mm)"
                
                return (startDate != nil ? formatter.stringFromDate(startDate!) : "<Неверный формат даты>") + " - " + (endDate != nil ? formatter.stringFromDate(endDate!) : "<Неверный формат даты>")
            }
            transformedServiceDetails.append([0: "Номер услуги", 1: externalServiceDetails["id"]])
            transformedServiceDetails.append([0: "Гостиница", 1: externalServiceDetails["title"]])
            transformedServiceDetails.append([0: "Номер", 1: externalServiceDetails["room_type"]])
            transformedServiceDetails.append([0: "Период проживания", 1: JSON(stay)])
            transformedServiceDetails.append([0: "Проживающие", 1: externalServiceDetails["persons"]])
            transformedServiceDetails.append([0: "Стоимость", 1: mainServiceDetails["price"]])
            transformedServiceDetails.append([0: "Статус", 1: mainServiceDetails["status"]])
            
        case "aeroexpress":
            var departureDate: String {
                let formatter = NSDateFormatter()
                
                /**
                *  MARK: - Specifying of the settings for NSDateFormatter() to parser was able to recognize the date.
                *          Locale identifier must be "ru-RU" for russian translation and both "en-US" and "en_US_POSIX" for US translation.
                *          For specifying of the time zone uncomment next snippet of code. // formatter.timeZone = NSTimeZone.localTimeZone()
                */
                formatter.locale = NSLocale(localeIdentifier: "ru-RU")
                formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                
                let departureDateString = externalServiceDetails["departure_date"].stringValue + " " + externalServiceDetails["departure_time"].stringValue
                
                let departureDate = formatter.dateFromString(departureDateString)
                
                /**
                *  MARK: - Changing of the settings for NSDateFormatter() to prepare it for transformation of the date to another format.
                */
                formatter.dateFormat = "d MMM yyyy (hh:mm:ss)"
                
                return departureDate != nil ? formatter.stringFromDate(departureDate!) : "<Неверный формат даты>"
            }
            transformedServiceDetails.append([0: "Номер услуги", 1: externalServiceDetails["id"]])
            transformedServiceDetails.append([0: "Аэроэкспресс", 1: externalServiceDetails["class"]])
            transformedServiceDetails.append([0: "Дата / время", 1: JSON(departureDate)])
            transformedServiceDetails.append([0: "Пассажир", 1: externalServiceDetails["passenger"]])
            transformedServiceDetails.append([0: "Стоимость", 1: mainServiceDetails["price"]])
            transformedServiceDetails.append([0: "Статус", 1: mainServiceDetails["status"]])
            
        case "avia":
            let numberInSpecificFormat = externalServiceDetails["id"].stringValue + " (" + externalServiceDetails["from_airport_code"].stringValue + " : " + externalServiceDetails["to_airport_code"].stringValue + ")"
            transformedServiceDetails.append([0: "Номер услуги", 1: JSON(numberInSpecificFormat)])
            let directFlight = externalServiceDetails["from_city"].stringValue + " → " + externalServiceDetails["to_city"].stringValue
            transformedServiceDetails.append([0: "Авиабилет", 1: JSON(directFlight)])
            var departureDate: [String] {
                let formatter = NSDateFormatter()
                
                /**
                *  MARK: - Specifying of the settings for NSDateFormatter() to parser was able to recognize the date.
                *          Locale identifier must be "ru-RU" for russian translation and both "en-US" and "en_US_POSIX" for US translation.
                *          For specifying of the time zone uncomment next snippet of code. // formatter.timeZone = NSTimeZone.localTimeZone()
                */
                formatter.locale = NSLocale(localeIdentifier: "ru-RU")
                formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                
                let departureDateTo = formatter.dateFromString(externalServiceDetails["from_date"].stringValue)
                let departureDateBack = formatter.dateFromString(externalServiceDetails["return_date"].stringValue)
                
                /**
                *  MARK: - Changing of the settings for NSDateFormatter() to prepare it for transformation of the date to another format.
                */
                formatter.dateFormat = "d MMM yyyy (hh:mm:ss)"
                
                if departureDateBack != nil {
                    return ["Туда: " + formatter.stringFromDate(departureDateTo!), "Назад: " + formatter.stringFromDate(departureDateBack!)]
                }
                else {
                    return ["Туда: " + formatter.stringFromDate(departureDateTo!)]
                }
            }
            transformedServiceDetails.append([0: "Дата / время вылета", 1: JSON(departureDate)])
            transformedServiceDetails.append([0: "Пассажиры", 1: nil])
            transformedServiceDetails.append([0: "Стоимость", 1: mainServiceDetails["price"]])
            transformedServiceDetails.append([0: "Статус", 1: mainServiceDetails["status"]])
            
        default: break
        }
        
        return transformedServiceDetails
    }
}
