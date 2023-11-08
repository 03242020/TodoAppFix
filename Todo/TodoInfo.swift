//
//  TodoInfo.swift
//  Todo
//
//  Created by ryo.inomata on 2023/09/27.
//

import Foundation

//TODO オプショナル型について調べる
struct TodoInfo {
    // Firestoreから取得するTodoのid,title,detail,idDoneを入れる配列を用意
    var todoId: String?
    var todoTitle: String?
    var todoDetail: String?
    var todoIsDone: Bool?
    var todoCreated: String?
    var todoUpdated: String?
    var todoScheduleDate: String?
    var todoScheduleTime: String?
    // var todoViewType: CategoryType?
    //Todo猪股
    var todoViewType: Int?
}


