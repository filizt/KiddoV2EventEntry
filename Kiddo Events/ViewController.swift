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

    @IBOutlet weak var eventImageObjectId: NSTextField!
    @IBOutlet weak var popularEventCheckButton: NSButton!
    @IBOutlet weak var eventActiveCheckButton: NSButton!
    @IBOutlet weak var freeEventCheckButton: NSButton!
    @IBOutlet weak var allDayCheckButton: NSButton!
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
    var dates = [Date]() {
        didSet {
            dateListTable.reloadData()
        }
    }

    var dateFormatter = DateFormatter()

    var imageFileUrl: URL?
    var isGeoLocationFound:Bool = false

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
                   }
    }

    var textFields = [NSTextField]()
    private var testData = [String: [String: Any]]()
    private var imageTestData = [String: [String: Any]]()
    var data = [String: Any]()

    var deleteUnusedPhotos = false

    //To-Do: Make this an Enum later
    let eventCategories = ["", "Storytime","Arts & Crafts","Indoor Play", "Indoor Activity", "Outdoor Activity", "Outdoor", "Mommy & Me","Museums","Nature & Science","Out & About","Parents Night Out","Shows & Concerts", "Movies", "Festivals & Fairs","Experience", "Seasonal & Holidays", "Place", "Music","Swimming","Mommy Only", "Indoor", "Other"]

    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.dateValue = Date()
        dateListTable.delegate = self
        dateListTable.dataSource = self

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
        cat3.addItems(withTitles: eventCategories)


        geoLocOKButton.layer?.backgroundColor = NSColor.blue.cgColor

        let pickerClick = NSClickGestureRecognizer(target: self, action: #selector(ViewController.handlePickerClick))
        pickerClick.numberOfClicksRequired = 2
        datePicker.addGestureRecognizer(pickerClick)

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
                print(obj.objectId, " to be deleted")
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

    func handlePickerClick() {
       // let dateWithSetComponents = DateUtil.shared.convertToUTCMidnight(from: datePicker.dateValue)
        let dateWithSetComponents = DateUtil.shared.createUTCDate(from: datePicker.dateValue)
        let dateToRemove = dates.filter{ $0 == dateWithSetComponents }


        if let date = dateToRemove.first {
            dates.remove(object: date)
            dateListTable.reloadData()
        } else {
            dates.append(dateWithSetComponents!)
        }
    }

    //For now we can just delete a date and can't update it.
    @IBAction func endEditingText(_ sender: NSTextField) {
        let row = dateListTable.row(for: sender)
        let column = dateListTable.column(for: sender)
       // print("Row: ", row)
        if sender.stringValue.isEmpty {
            if dates.count > row {
                //print("dates.count", dates.count)
                dates.remove(at: row)
            }
        }
        dateListTable.reloadData()
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

//    func addDate(_ sender: Any) {
//        let date = datePicker.dateValue
//        let calendar = NSCalendar.current
//        let components = calendar.dateComponents([.day, .year, .month], from: date)
//        let dateWithSetComponents = calendar.date(from: components)!
//        dates.append(dateWithSetComponents)
//    }

    @IBAction func doneButtonClicked(_ sender: Any) {
        if editingEvent {
            objectToBeEdited?["allEventDates"] = self.dates

//            if self.location.stringValue != objectToBeEdited!["location"] as! String {
//                objectToBeEdited!["location"] = location.stringValue
//                objectToBeEdited!["address"] = locationAddress.stringValue
//                objectToBeEdited!["geoLocation"] = geoLocation
//            }
//            self.dateFormatter.dateFormat = "h:mm a"
//            objectToBeEdited?["startTime"] = eventStartTimePicker.isEnabled ? dateFormatter.string(from: eventStartTimePicker.dateValue) : ""
//            objectToBeEdited?["endTime"] = eventEndTimePicker.isEnabled ? dateFormatter.string(from: eventEndTimePicker.dateValue) : ""

            guard saveToParse() else { return }
            self.performSegue(withIdentifier: "alertView", sender: nil)
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

    private func specialEventEntry() {

        let SpecialEventReq: PFObject = PFObject(className: "SeasonalEvents")
        SpecialEventReq["isEnabled"] = true
        SpecialEventReq["name"] = ""

        //event object has all the date it needs. Save it now. In the completion handler
        //we can check which dates it needs to have relation with.
        guard let _ = try? SpecialEventReq.save() else { return  }
        //print("Event object saved")

    }

    private func setImageCacheLimit() {
        let cacheObject: PFObject = PFObject(className: "ImageCache")
        cacheObject["limit"] = 50

        guard let _ = try? cacheObject.save() else { return }
    }

    private func saveToParse() -> Bool {

        if editingEvent {
            let alleventdates = objectToBeEdited?["allEventDates"] as! [Date];

            guard let _ = try? objectToBeEdited?.save() else { return false }

            for date in alleventdates {
                //let date = alleventdates[0]
                let q = PFQuery(className: "EventDate")
                q.whereKey("eventDate", equalTo: date)
                if let eventDateObjects = try? q.findObjects() {
                    if eventDateObjects.count == 0 {
                        let dateObject: PFObject = PFObject(className: "EventDate")
                        dateObject["eventDate"] = date
                        let relation = dateObject.relation(forKey: "events")
                        relation.add(objectToBeEdited!)
                        guard let _ = try? dateObject.save() else { return false }
                        //print("Date object created and event object linked to the date object")
                    } else {
                        let existingDateObject = eventDateObjects[0]
                        let relation = existingDateObject.relation(forKey: "events")
                        relation.add(objectToBeEdited!)
                        guard let _ = try? existingDateObject.save() else { return false }
                        //print("Event object linked to existing date object")
                    }
                }
            }
            return true
        }


        guard data.count > 0 else { return false }

        let eventObject: PFObject = PFObject(className: "EventObject")
        eventObject["title"] = data["title"]
        eventObject["allEventDates"] = data["allEventDates"] as! [Date];
        eventObject["startDate"] = data["startDate"] as! Date
        eventObject["endDate"] = data["endDate"] as! Date
        eventObject["allDay"] = false
        eventObject["startTime"] = data["startTime"] as? String
        eventObject["endTime"] = data["endTime"] as? String
        eventObject["free"] = data ["free"] as! Bool
        eventObject["price"] =  data["price"] as! String
        eventObject["originalEventURL"] = data["originalEventURL"] as! String
        eventObject["location"] = data["location"] as! String
        eventObject["locationHours"] = " "
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

        let alleventdates = data["allEventDates"] as! [Date];

        //event object has all the date it needs. Save it now. In the completion handler
        //we can check which dates it needs to have relation with.
        guard let _ = try? eventObject.save() else { return false }
        //print("Event object saved")

        for date in alleventdates {
            //let date = alleventdates[0]
            let q = PFQuery(className: "EventDate")
            q.whereKey("eventDate", equalTo: date)
            if let eventDateObjects = try? q.findObjects() {
                if eventDateObjects.count == 0 {
                    let dateObject: PFObject = PFObject(className: "EventDate")
                    dateObject["eventDate"] = date
                    let relation = dateObject.relation(forKey: "events")
                    relation.add(eventObject)
                    guard let _ = try? dateObject.save() else { return false }
                    //print("Date object created and event object linked to the date object")
                } else {
                    let existingDateObject = eventDateObjects[0]
                    let relation = existingDateObject.relation(forKey: "events")
                    relation.add(eventObject)
                    guard let _ = try? existingDateObject.save() else { return false }
                    //print("Event object linked to existing date object")
                }
            }
        }
        return true
    }


    private func prepareData() -> Bool {
        data = [String: Any]()
        data["title"] = eventTitle.stringValue
        data["allEventDates"] = self.dates
        data["startDate"] = Date()
        data["endDate"] = Date()
        data["allDay"] = false
        self.dateFormatter.dateFormat = "h:mm a"
        data["startTime"] = eventStartTimePicker.isEnabled ? dateFormatter.string(from: eventStartTimePicker.dateValue) : ""
        data["endTime"] = eventEndTimePicker.isEnabled ? dateFormatter.string(from: eventEndTimePicker.dateValue) : ""
        data["free"] = freeEventCheckButton.state != 0 ? true : false
        data["price"] = eventPriceField.stringValue
        data["originalEventURL"] = eventURL.stringValue
        data["location"] = location.stringValue
        data["locationHours"] = " "
        data["address"] = locationAddress.stringValue
        data["description"] = eventDescription.stringValue
        data["ages"] = eventAges.stringValue
        data["imageURL"] = ""
        data["isActive"] = eventActiveCheckButton.state != 0 ? true : false
        data["isPopular"] = popularEventCheckButton.state != 0 ? true : false
        data["category"] = eventCategories[categoryList.indexOfSelectedItem]
        data["isFeatured"] = featuredCheckButton.state != 0 ? true : false
        data["geoLocation"] = geoLocation
        //var catKeywords = ["Indoor", "Shows & Concerts"]
        let categories = [eventCategories[categoryList.indexOfSelectedItem], eventCategories[cat2.indexOfSelectedItem], eventCategories[cat3.indexOfSelectedItem]]
        data["categoryKeywords"] = categories

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

        //check if table has at least one entry
        if dates.count == 0 {
            dateListTable.backgroundColor = NSColor.red
            validationResult = false
        } else {
            dateListTable.backgroundColor = NSColor.white
        }

        //for now category field can be empty
        if categoryList.indexOfSelectedItem == 0 {
             validationResult = false
        }

        if isGeoLocationFound == false {
            validationResult = false
            geoLocOKButton.layer?.backgroundColor = NSColor.red.cgColor
        }


        return validationResult
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
        return self.dates.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = dateListTable.make(withIdentifier: "dateCell", owner: nil) as? NSTableCellView {
            self.dateFormatter.dateFormat = "MM-dd-YYYY"
            //print(dates[row])
            cell.textField?.stringValue =  self.dateFormatter.string(from: dates[row])
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
                    print("new date", DateUtil.shared.convertToUTCMidnight(from: object["eventDate"] as! Date))
                    object["eventDate"] = DateUtil.shared.convertToUTCMidnight(from: object["eventDate"] as! Date)
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
                print("new date", DateUtil.shared.convertToUTCMidnight(from: dateObject["eventDate"] as! Date))
                //object["eventDate"] = DateUtil.shared.convertToUTCMidnight(from: dateObject["eventDate"] as! Date))
                //object.saveInBackground()
            }
        }
    }

//    func bulkUpdateEventDateList() {
//        let allEventDateObjectsQuery = PFQuery(className: "EventObject")
//        allEventDateObjectsQuery.limit = 100
//        if let objects = try? allEventDateObjectsQuery.findObjects() {
//            for object in objects {
//                print("old date", object["eventDate"])
//                print("new date", DateUtil.shared.convertToUTCMidnight(from: object["eventDate"] as! Date))
//
//                var dates = object["allEventDates"] as! [Date]
//                var newDates = [Date]()
//                for date in dates {
//                    if let newDate: Date = DateUtil.shared.convertToUTCMidnight(from:date) {
//                        newDates.append(newDate)
//                    }
//                }
//                object["allEventDates"] = newDates
//                object.saveInBackground()
//            }
//        }
//    }
}

extension Array where Element: Equatable {

    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}


