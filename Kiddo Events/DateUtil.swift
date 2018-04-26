//
//  DateUtil.swift
//  Kiddo Events
//
//  Created by Filiz Kurban on 3/30/17.
//  Copyright © 2017 Filiz Kurban. All rights reserved.
//

import Foundation

class DateUtil {

    private let formatter: DateFormatter
    static let shared = DateUtil()

    private init() {
        formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
    }


    //below I'm creating an absoulte value here. This is donw with Datecomponents. If there was no UTC set as timezone, Calendar assumes PST(system time zone) and converts dateComp(which is created in UTC) to PST. This is a correct behaviour however I want to manupulate the hour value, so I'm forcing it to create an UTC date with set hour.
    func formattedDateValueWithHourZeroZero(date: Date) -> Date? {
        var dateComp = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComp.timeZone = TimeZone(abbreviation: "UTC") // makes it fixed so UTC conversion doesn't happen.
        return Calendar.current.date(from:dateComp)
    }

    func UTCdateValue(date: Date) -> Date? {
        var components = Calendar.current.dateComponents([.day , .month, .year, .hour, .minute, .second], from: date)
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(abbreviation: "UTC")
        return Calendar.current.date(from: components)
    }

    func formattedTimeValue(time: Date) -> String {
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from:time)
    }

    func shortFormattedTimeValue(time: Date) -> String {
        formatter.dateFormat = "h:mm a"
        return formatter.string(from:time)
    }

    func concetenateDateAndTime(date: Date, time:Date ) -> Date? {

        var timeComponents = Calendar.current.dateComponents([.hour, .minute, .second ], from: time)
        var dateComponents =  Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = timeComponents.second
        print(dateComponents.timeZone)
        print(timeComponents.timeZone)
        print( Calendar.current.date(from: dateComponents))

        return Calendar.current.date(from: dateComponents)
    }

}
