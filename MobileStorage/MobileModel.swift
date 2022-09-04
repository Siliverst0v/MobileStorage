//
//  MobileModel.swift
//  MobileStorage
//
//  Created by Анатолий Силиверстов on 04.09.2022.
//

import RealmSwift

class Mobile: Object {
    @Persisted var imei: String
    @Persisted var model: String
    
    convenience init(imei: String, model: String) {
        self.init()
        self.imei = imei
        self.model = model
    }
}
