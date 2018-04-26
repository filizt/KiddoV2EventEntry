//
//  ViewController.swift
//  Kiddo Events
//
//  Created by Filiz Kurban on 3/1/17.
//  Copyright © 2017 Filiz Kurban. All rights reserved.
//

import Cocoa
import Parse
import CoreLocation

//enum Catagories: Int {
//    case ArtsCraftsMusicSwim = 1, IndoorPlay, OutdoorPlay,"Mommy and Me","Museums","Nature/Science","Out and About","Outdoor Activity","Parent's Date Night","Shows/Concerts/Theatre","Festival and Fairs","CoffeeShop","Brewery","Others"
//}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var eventTitle: NSTextField!
    @IBOutlet weak var location: NSTextField!
    @IBOutlet weak var addDateButton: NSButton!
    @IBOutlet weak var datePicker: NSDatePicker!
    @IBOutlet weak var dateListTable: NSTableView!
    @IBOutlet weak var doneButton: NSButton!

    @IBOutlet weak var ticketsURL: NSTextField!
    @IBOutlet weak var discountedTicketsURL: NSTextField!
    @IBOutlet weak var discountedSessionsTable: NSTableView!
    @IBOutlet weak var eventImageObjectId: NSTextField!
    @IBOutlet weak var popularEventCheckButton: NSButton!
    @IBOutlet weak var eventActiveCheckButton: NSButton!
    @IBOutlet weak var freeEventCheckButton: NSButton!
    @IBOutlet weak var eventDescription: NSTextField!
    @IBOutlet weak var categoryList: NSPopUpButton!
    @IBOutlet weak var eventAges: NSTextField!
    @IBOutlet weak var eventURL: NSTextField!
    @IBOutlet weak var locationAddress: NSTextField!
    @IBOutlet weak var eventPriceField: NSTextField!
    @IBOutlet weak var eventEndTimePicker: NSDatePicker!
    @IBOutlet weak var eventStartTimePicker: NSDatePicker!
    @IBOutlet weak var featuredCheckButton: NSButton!
    @IBOutlet weak var geoLocOKButton: NSButton!
    @IBOutlet weak var eventObjectIdTextfield: NSTextField!
    @IBOutlet weak var cat3: NSPopUpButton!
    @IBOutlet weak var cat2: NSPopUpButton!
    @IBOutlet weak var deletePhotosButton: NSButton!
    var editingEvent = false
    var objectToBeEdited: PFObject? {
        didSet {
            editingEvent = true
            eventObjectIdTextfield.isEnabled = false
            parseEventInfoForScreen()
        }
    }

    var geoLocation = PFGeoPoint()

    @IBOutlet weak var discountedTicketsPrice: NSTextField!
    //var eventDateTimeDict = [ Date: [Date] ]()
    var eventDateTimeList = [(Date,Date)]()
    var discountedSessionsList = [(Date,Date)]()
    var imageFileUrl: URL?
    var isGeoLocationFound:Bool = false

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
                   }
    }

    var textFields = [NSTextField]()
    var data = [String: Any]()

    var deleteUnusedPhotos = false

    //To-Do: Make this an Enum later
    let eventCategories = ["Categories", "Storytime","Arts & Crafts","Indoor Play", "Indoor Activity", "Outdoor Activity", "Outdoor", "Indoor", "Mommy & Me","Museums","Nature & Science","Out & About","Parents Night Out","Shows & Concerts", "Movies", "Festivals & Fairs","Experience", "Seasonal & Holidays", "Place", "Music","Swimming","Mommy Only", "Other"]
    let eventKeywords = ["Keywords", "Events", "Indoor", "Activity"]

    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.dateValue = Date()
        dateListTable.delegate = self
        dateListTable.dataSource = self

        discountedSessionsTable.delegate = self
        discountedSessionsTable.dataSource = self

        textFields.append(eventTitle)
        textFields.append(location)
        textFields.append(locationAddress)
        textFields.append(eventPriceField)
        textFields.append(eventAges)
        textFields.append(eventImageObjectId)

        categoryList.removeAllItems()
        categoryList.addItems(withTitles: eventCategories)

        cat2.removeAllItems()
        cat2.addItems(withTitles: eventCategories)

        cat3.removeAllItems()
        cat3.addItems(withTitles: eventKeywords)


        geoLocOKButton.layer?.backgroundColor = NSColor.blue.cgColor

//        let pickerClick = NSClickGestureRecognizer(target: self, action: #selector(ViewController.handlePickerClick))
//        pickerClick.numberOfClicksRequired = 1
//        datePicker.addGestureRecognizer(pickerClick)
//


    }

    private func validateFields() -> Bool {
        var validationResult = true
        //check textFields
        for field in textFields {
            if field.stringValue.isEmpty {
                //exclude event price field, if event is free
                if field == eventPriceField && freeEventCheckButton.state == 1 {
                    field.backgroundColor = NSColor.white
                    continue
                }

                validationResult = false
                //field.layer?.borderColor = NSColor.red.cgColor
                field.backgroundColor = NSColor.red
            } else {
                field.backgroundColor = NSColor.white
            }
        }

        //check eventDescription
        if eventDescription.stringValue.isEmpty {
            eventDescription.backgroundColor = NSColor.red
            validationResult = false
        } else {
            eventDescription.backgroundColor = NSColor.white

        }

        if categoryList.indexOfSelectedItem == 0 {
            validationResult = false
        }

        if cat2.indexOfSelectedItem == 0 {
            validationResult = false
        }

        if cat3.indexOfSelectedItem == 0 {
            validationResult = false
        }

        if isGeoLocationFound == false {
            validationResult = false
            geoLocOKButton.layer?.backgroundColor = NSColor.red.cgColor
        }

        if discountedSessionsList.count > 0 {
            if discountedTicketsURL.stringValue.isEmpty  || discountedTicketsPrice.stringValue.isEmpty {
                validationResult = false
                let alert = NSAlert.init()
                alert.messageText = "Discounted Tickets URL and Discounted Tickets Price field should be filled"
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }

        if eventDateTimeList.count == 0 {
            validationResult = false
            let alert = NSAlert.init()
            alert.messageText = "Enter at least one event date"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }

        return validationResult
    }

    private func prepareData() -> Bool {
        data = [String: Any]()
        data["title"] = eventTitle.stringValue
        data["allDay"] = false
        data["free"] = freeEventCheckButton.state != 0 ? true : false
        data["price"] = eventPriceField.stringValue
        data["originalEventURL"] = eventURL.stringValue
        data["location"] = location.stringValue
        data["address"] = locationAddress.stringValue
        data["description"] = eventDescription.stringValue
        data["ages"] = eventAges.stringValue
        data["imageURL"] = ""
        data["isActive"] = eventActiveCheckButton.state != 0 ? true : false
        data["isPopular"] = popularEventCheckButton.state != 0 ? true : false
        data["isFeatured"] = featuredCheckButton.state != 0 ? true : false
        data["geoLocation"] = geoLocation
        data["category"] = eventCategories[categoryList.indexOfSelectedItem] //main catagory
        let categories = [eventCategories[categoryList.indexOfSelectedItem], eventCategories[cat2.indexOfSelectedItem], eventKeywords[cat3.indexOfSelectedItem]]
        data["categoryKeywords"] = categories
        data["ticketsURL"] = ticketsURL.stringValue
        data["discountedTicketsURL"] = discountedTicketsURL.stringValue
        data["allEventDates"] = eventDateTimeList.flatMap { $0.0 }
        data["discountedTicketPrice"] = discountedTicketsPrice.stringValue
        //prepared allEventDates
        //var eventDateList = [Date]()
//        for dt in eventDateTimeStartList {
//            if let date = DateUtil.shared.UTCdateValue(date: dt) {
//                eventDateList.append(date)
//            }
//        }

        var eventInstancesDictionary = [[String:Date]]()

        for item in eventDateTimeList {
            var dict = [String:Date]()
            dict["startTime"] = item.0
            dict["endTime"] = item.1
            eventInstancesDictionary.append(dict)
        }

        data["eventInstances"] = eventInstancesDictionary

        var eventDiscountedInstancesList = [[String:Date]]()

        for item in discountedSessionsList {
            var dict = [String:Date]()
            dict["startTime"] = item.0
            dict["endTime"] = item.1
            eventDiscountedInstancesList.append(dict)
        }

        data["discountedTicketInstances"] = eventDiscountedInstancesList


        if let imageFileUrl = imageFileUrl { //if this is true, it means upload new image.
            if let imageData = try? Data(contentsOf: imageFileUrl) {
                var fileName = imageFileUrl.deletingPathExtension().lastPathComponent
                guard let imgObjId = uploadEventImage(data: imageData, imageName: fileName) else { print("CANT GET IMAGE OBJECT ID"); return false }
                eventImageObjectId.stringValue = imgObjId
            }
        }

        data["imageObjectId"] = eventImageObjectId.stringValue

        return true
    }

    private func saveToParse() -> Bool {

        if editingEvent {
            //            let alleventdates = objectToBeEdited?["allEventDates"] as! [Date];
            //            guard let _ = try? objectToBeEdited?.save() else { return false }
            //
            //            for date in alleventdates {
            //                //let date = alleventdates[0]
            //                let q = PFQuery(className: "EventDate")
            //                q.whereKey("eventDate", equalTo: date)
            //                if let eventDateObjects = try? q.findObjects() {
            //                    if eventDateObjects.count == 0 {
            //                        let dateObject: PFObject = PFObject(className: "EventDate")
            //                        dateObject["eventDate"] = date
            //                        let relation = dateObject.relation(forKey: "events")
            //                        relation.add(objectToBeEdited!)
            //                        guard let _ = try? dateObject.save() else { return false }
            //                        //print("Date object created and event object linked to the date object")
            //                    } else {
            //                        let existingDateObject = eventDateObjects[0]
            //                        let relation = existingDateObject.relation(forKey: "events")
            //                        relation.add(objectToBeEdited!)
            //                        guard let _ = try? existingDateObject.save() else { return false }
            //                        //print("Event object linked to existing date object")
            //                    }
            //                }
            //            }
            return true
        }


        //guard data.count > 0 else { return false }

        let eventObject: PFObject = PFObject(className: "Event")
        eventObject["title"] = data["title"]
        eventObject["allEventDates"] = data["allEventDates"] as! [Date]
        eventObject["allDay"] = false
        eventObject["free"] = data ["free"] as! Bool
        eventObject["price"] =  data["price"] as! String
        eventObject["originalEventURL"] = data["originalEventURL"] as! String
        eventObject["location"] = data["location"] as! String
        eventObject["address"] = data["address"] as! String
        eventObject["description"] = data["description"] as! String
        eventObject["ages"] = data["ages"] as! String
        eventObject["imageURL"] = data["imageURL"] as! String
        eventObject["isActive"] = data["isActive"] as! Bool
        eventObject["isPopular"] = data["isPopular"] as! Bool
        eventObject["isFeatured"] = data["isFeatured"] as! Bool
        eventObject["imageObjectId"] = data["imageObjectId"] as! String
        eventObject["category"] = data["category"] as! String
        eventObject["isSpecialEvent"] = false
        eventObject["geoLocation"] = data["geoLocation"] as! PFGeoPoint
        eventObject["categoryKeywords"] = data["categoryKeywords"] as! [String]
        eventObject["ticketsURL"] = data["ticketsURL"]
        eventObject["discountedTicketInstances"] = data["discountedTicketInstances"] as? [[String:Date]]
        eventObject["discountedTicketsURL"] = data["discountedTicketsURL"]
        eventObject["discountedTicketPrice"] = data["discountedTicketPrice"]
        eventObject["eventInstances"] = data["eventInstances"] as! [[String:Date]]

        let alleventdates = data["allEventDates"] as! [Date] //these are start dates

        for date in alleventdates {
            //let date = alleventdates[0]
            let eventInstance: PFObject = PFObject(className: "EventInstance")
            eventInstance["eventDate"] = date
            eventInstance["eventImageId"] = data["imageObjectId"] as! String
            eventInstance["eventTitle"] = data["title"] as! String

            guard let ins = try? eventInstance.save() else { return false }
            //print("Date object created and event object linked to the date object")

            eventObject.add(eventInstance, forKey: "eventInstanceObjects")
        }


        guard let _ = try? eventObject.save() else { return false }

//        for date in alleventdates {
//            //let date = alleventdates[0]
//            let q = PFQuery(className: "TestEventDate")
//            q.whereKey("eventDate", equalTo: date)
//            if let eventDateObjects = try? q.findObjects() {
//                if eventDateObjects.count == 0 {
//                    let dateObject: PFObject = PFObject(className: "TestEventDate")
//                    dateObject["eventDate"] = date
//                    let relation = dateObject.relation(forKey: "events")
//                    relation.add(eventObject)
//                    guard let _ = try? dateObject.save() else { return false }
//                    //print("Date object created and event object linked to the date object")
//                } else {
//                    let existingDateObject = eventDateObjects[0]
//                    let relation = existingDateObject.relation(forKey: "events")
//                    relation.add(eventObject)
//                    guard let _ = try? existingDateObject.save() else { return false }
//                    //print("Event object linked to existing date object")
//                }
//            }
//        }
        return true
    }

    @IBAction func clearDiscountedSessionsTable(_ sender: Any) {
        discountedSessionsList = []
        discountedSessionsTable.reloadData()
    }

    @IBAction func clearEventDatesTable(_ sender: Any) {
        eventDateTimeList = [(Date,Date)]()
        dateListTable.reloadData()
    }

    @IBAction func deletePhotosPressed(_ sender: Any) {
        if deletePhotosButton.state == 1 {

        let query = PFQuery(className: "EventImage")
        query.limit = 300
        let eventImageObjects = try? query.findObjects()

        if let objects = eventImageObjects {
            var counter = 0
            for obj in objects {
                let query2 = PFQuery(className: "EventObject")
                query2.whereKey("imageObjectId", equalTo: obj.objectId)
                //print(obj.imageName, " to be deleted")
                //print(obj.objectId, " to be deleted")
                let eventobj = try? query2.getFirstObject()
                if eventobj != nil {
                        //there is a event with that image, continue
                    } else {
                        //no event with that image, delete image object
                       let deleted = try? obj.delete()
                        if deleted != nil {
                            print(obj.objectId, " deleted")
                            counter = counter + 1
                        }
                    }
            }

            print("Total deleted images: ", counter)

        }

        }
    }

    @IBAction func datePickerClicked(_ sender: NSDatePicker) {
        handlePickerClick()
    }


    func handlePickerClick() {
        if let startDateTime = DateUtil.shared.concetenateDateAndTime(date: datePicker.dateValue, time: eventStartTimePicker.dateValue) {
            let endDateTime = DateUtil.shared.concetenateDateAndTime(date: datePicker.dateValue, time: eventEndTimePicker.dateValue)!

            if startDateTime >= endDateTime {
                let alert = NSAlert.init()
                alert.messageText = "Event start time should be less than event end time"
                alert.addButton(withTitle: "OK")
                alert.runModal()

                return
            }

            if eventDateTimeList.contains(where: { $0 == (startDateTime, endDateTime) } ) {
                return
            }

            eventDateTimeList.append((startDateTime, endDateTime))
        }

        dateListTable.reloadData()
    }


    @IBAction func endEditingText(_ sender: NSTextField) {

        if dateListTable.selectedRow == -1 {
            //it's the other table
            let editedRowIndex = discountedSessionsTable.selectedRow
            _ = discountedSessionsList.remove(at: editedRowIndex)

            discountedSessionsTable.reloadData()
        } else {

            let editedRowIndex = dateListTable.selectedRow
            _ = eventDateTimeList.remove(at: editedRowIndex)

            dateListTable.reloadData()
        }

    }

    @IBAction func editEventSelected(_ sender: Any) {
        //Pull information about 

        if !eventObjectIdTextfield.stringValue.isEmpty {
            let query = PFQuery(className: "EventObject")
            query.getObjectInBackground(withId: eventObjectIdTextfield.stringValue) {(object, error) -> Void in
                guard let object = object else { return }
                self.objectToBeEdited = object
            }
        }
    }

    @IBAction func eventCategoryPicked(_ sender: NSPopUpButton) {
       // print("Pop-up category item chosen:", sender.indexOfSelectedItem)
    }


    @IBAction func addToDiscountedSessionsList(_ sender: NSButton) {
        //var selectedIndexes = dateListTable.selectedRowIndexes
        if dateListTable.selectedRow == -1 {
            return
        }

        var discountedSession = eventDateTimeList[dateListTable.selectedRow]
        let value = eventDateTimeList[dateListTable.selectedRow]

        if discountedSessionsList.contains( where: { $0 == value } ) {
            return
        }

        self.discountedSessionsList.append(discountedSession)
        discountedSessionsTable.reloadData()

    }

    @IBAction func doneButtonClicked(_ sender: Any) {
        if editingEvent {
//            objectToBeEdited?["allEventDates"] = Array(self.eventDateTimeDict.keys)
//
//            var count = 0
//            for (key,value) in eventDateTimeDict {
//                count = count + value.count
//            }
//
//            if count != dates.count {
//                dateListTable.backgroundColor = NSColor.red
//                let alert = NSAlert.init()
//                alert.messageText = "EDIT EVENT: Dates mismatch!!!"
//                alert.addButton(withTitle: "OK")
//                alert.runModal()
//                return
//            }

//            if self.location.stringValue != objectToBeEdited!["location"] as! String {
//                objectToBeEdited!["location"] = location.stringValue
//                objectToBeEdited!["address"] = locationAddress.stringValue
//                objectToBeEdited!["geoLocation"] = geoLocation
//            }
//            self.dateFormatter.dateFormat = "h:mm a"
//            objectToBeEdited?["startTime"] = eventStartTimePicker.isEnabled ? dateFormatter.string(from: eventStartTimePicker.dateValue) : ""
//            objectToBeEdited?["endTime"] = eventEndTimePicker.isEnabled ? dateFormatter.string(from: eventEndTimePicker.dateValue) : ""

 //           guard saveToParse() else { return }
 //           self.performSegue(withIdentifier: "alertView", sender: nil)
        } else {
            guard validateFields() else { return }
            guard prepareData() else { return }
            guard saveToParse() else { return }
            //if everything above is true then show success pop-up
            performSegue(withIdentifier: "alertView", sender: nil)
        }
    }

    private func parseEventInfoForScreen() {

        if let object = objectToBeEdited {
            eventTitle.stringValue = object["title"] as! String
            eventDescription.stringValue = object["description"] as! String
            location.stringValue = object["location"] as! String

            locationAddress.stringValue = object["address"] as! String
            eventPriceField.stringValue = object["price"] as? String ?? ""
            eventURL.stringValue = object["originalEventURL"] as? String ?? ""
            eventAges.stringValue = object["ages"] as! String

            featuredCheckButton.state = object["isFeatured"] as! Bool == true ? NSOnState : NSOffState
            //CheckButton.state = object["allDay"] as! Bool == true ? NSOnState : NSOffState
            freeEventCheckButton.state = object["free"] as! Bool == true ? NSOnState : NSOffState
            eventActiveCheckButton.state = object["isActive"] as! Bool == true ? NSOnState : NSOffState
            popularEventCheckButton.state = object["isPopular"] as! Bool == true ? NSOnState : NSOffState

            eventImageObjectId.stringValue = object["imageObjectId"] as! String

            //For now time information will not show. We can still update it, but it won't show from the existing event.
//            if let timeString = object["endTime"] as? String, (dateFormatter.date(from: timeString) != nil) {
//                print(dateFormatter.date(from: timeString)!)
//                eventEndTimePicker.dateValue = dateFormatter.date(from: timeString)!
//            }
            //eventStartTimePicker: NSDatePicker!

            if let category = object["category"] as? String {
                categoryList.selectItem(withTitle: category)

            }

        }

    }

    private func setImageCacheLimit() {
        let cacheObject: PFObject = PFObject(className: "ImageCache")
        cacheObject["limit"] = 50

        guard let _ = try? cacheObject.save() else { return }
    }



    @IBAction func freeEventPicked(_ sender: NSButton) {
        //if let sender = freeEventCheckButton as! NSButton {
            switch sender.state {
            case NSOnState:
                eventPriceField.isEnabled = false
            case NSOffState:
                eventPriceField.isEnabled = true
            default:
                print("should not hit here")
            }
        //}
    }




    @IBAction func addressReverseLookUp(_ sender: Any) {
        let geocoder = CLGeocoder()
        let address = locationAddress.stringValue

        geocoder.geocodeAddressString(address, completionHandler: {[weak weakSelf = self] (placemarks, error) -> Void in
            guard error == nil else { return }

            if let placemark = placemarks?.first {
                if let location = placemark.location {
                    weakSelf?.geoLocation = PFGeoPoint(location: location)
                    weakSelf?.geoLocOKButton.title = "✓"
                    weakSelf?.isGeoLocationFound = true
                    weakSelf?.geoLocOKButton.layer?.backgroundColor = NSColor.blue.cgColor
                }
            }
        })
    }


    @IBAction func browseFiles(_ sender: Any) {

        //uploadImages()
        //bulkUpdateEventDateTimes()


        let dialog = NSOpenPanel();

        dialog.title                   = "Choose a .txt file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["jpeg"];

        if (dialog.runModal() == NSModalResponseOK) {
            if let result = dialog.url {
                imageFileUrl = result
                eventImageObjectId.stringValue = result.lastPathComponent
            }
        } else {
            // User clicked on "Cancel"
            return
        }
        
    }



    private func uploadImages() {

        let url1 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url2 = url1.appendingPathComponent("/KiddoEventPhotos/ToBeUploaded")
        let properties = [URLResourceKey.localizedNameKey,
                          URLResourceKey.creationDateKey, URLResourceKey.localizedTypeDescriptionKey]

        let fileList = try? FileManager.default.contentsOfDirectory(at: url2, includingPropertiesForKeys: properties, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)

        guard (fileList != nil) else { return }

        var count = 0

        for url in fileList! {
            if let imageData = try? Data(contentsOf: url) {
                var fileName = url.deletingPathExtension().lastPathComponent
                uploadEventImage(data: imageData, imageName: fileName)
                print("image URL: \(url.lastPathComponent)")
                count = count + 1
            }
        }
        //print("Total images uploaded: ", count)

    }

    private func uploadEventImage(data: Data, imageName: String) -> String? {

        let eventImage = PFObject(className: "EventImage")
        eventImage["category"] = imageName
        eventImage["imageName"] = imageName

        let imagePFFile = PFFile(data: data, contentType: "image/jpeg")
        eventImage["image"] = imagePFFile
        guard let _ = try? imagePFFile.save() else { print("PFFILE IS NOT SAVED!!! ", imageName); return "0" }
        guard let _ = try? eventImage.save() else { print("IMAGE IS NOT SAVED!!! ", imageName); return "0" }

        return eventImage.objectId

    }


    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == discountedSessionsTable {
            return discountedSessionsList.count
        } else {
            return eventDateTimeList.count //Array(self.eventDateTimeDict.values.flatMap { $0 }).count
        }
    }


    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = dateListTable.make(withIdentifier: "dateCell", owner: nil) as? NSTableCellView {
            let item = eventDateTimeList[row]
            let dateString = DateUtil.shared.formattedTimeValue(time: item.0) + " - " + DateUtil.shared.shortFormattedTimeValue(time: item.1)
            cell.textField?.stringValue = dateString
            return cell
        } else if let cell = dateListTable.make(withIdentifier: "discountedSessionsCell", owner: nil) as? NSTableCellView {
            let item = discountedSessionsList[row]
            let dateString = DateUtil.shared.formattedTimeValue(time: item.0) + " - " + DateUtil.shared.shortFormattedTimeValue(time: item.1)
            cell.textField?.stringValue = dateString
            return cell
        }
        return nil
    }

    func bulkUpdateEventDateTimes() {
        let allEventDateObjectsQuery = PFQuery(className: "EventDate")
        allEventDateObjectsQuery.limit = 200
        if let objects = try? allEventDateObjectsQuery.findObjects() {
                for object in objects {
                    print("old date", object["eventDate"])
                    //print("new date", DateUtil.shared.convertToUTCMidnight(from: object["eventDate"] as! Date))
                    //object["eventDate"] = DateUtil.shared.convertToUTCMidnight(from: object["eventDate"] as! Date)
                    object.saveInBackground()
                }
        }
    }

    func addNewEventDateTimes() {
        let allEventDateObjectsQuery = PFQuery(className: "EventDate")
        allEventDateObjectsQuery.limit = 200
        if let dateObjects = try? allEventDateObjectsQuery.findObjects() {
            for dateObject in dateObjects {
                print("old date", dateObject["eventDate"])
                //print("new date", DateUtil.shared.convertToUTCMidnight(from: dateObject["eventDate"] as! Date))
                //object["eventDate"] = DateUtil.shared.convertToUTCMidnight(from: dateObject["eventDate"] as! Date))
                //object.saveInBackground()
            }
        }
    }
}

extension Array where Element: Equatable {

    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}


