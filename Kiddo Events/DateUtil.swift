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
        formatter.timeZone = TimeZone(abbreviation: "UTC")
    }

    func convertToUTCMidnight(from date: Date) -> Date? {
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.timeZone = TimeZone(abbreviation: "UTC")

        return Calendar.current.date(from: dateComponents)

    }

    func createUTCDate(from date: Date) -> Date? {
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        dateComponents.timeZone = TimeZone(abbreviation: "UTC")

        return Calendar.current.date(from:dateComponents)
    }

    func concetenateDateAndTime(date: Date, time:String ) -> Date {
        formatter.dateFormat = "h:mm a"
        let timeObj = formatter.date(from:time)
        var timeComponents = Calendar.current.dateComponents([.hour, .minute, ], from: timeObj!)
        timeComponents.timeZone = TimeZone(abbreviation: "UTC")

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.timeZone = TimeZone(abbreviation: "UTC")

        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute

      //  guard let laterDate = Calendar.current.date(byAdding: dateComponents, to: createDate(from:today())) else { return nil }

        return Calendar.current.date(from: dateComponents)!

    }




}
