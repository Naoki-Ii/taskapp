//
//  ViewController.swift
//  taskapp
//
//  Created by NAOKI II on 2020/02/19.
//  Copyright © 2020 NAOKI.II. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController,UITableViewDelegate,UISearchBarDelegate, UITableViewDataSource {
    
    @IBOutlet weak var CategorySerch: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let realm = try!Realm()
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        CategorySerch.delegate = self
        CategorySerch.text = ""
        
        //何も押されてなくてもreturnできるようにする。
        CategorySerch.enablesReturnKeyAutomatically = false
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    //サーチバー検索
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.CategorySerch.endEditing(true)
        
        if (CategorySerch.text == "") {
            taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        }else {
            // 文字列で検索条件を指定します
            let filter = realm.objects(Task.self).filter("category == %@", CategorySerch.text!)
            print ("filter\(filter)")
            taskArray = filter
            }
        
        
        self.tableView.reloadData()
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        CategorySerch.showsCancelButton = false
        self.view.endEditing(true)
        CategorySerch.text = ""
        taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        self.tableView.reloadData()
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        CategorySerch.showsCancelButton = true
        return true
    }
    
    
    
        //segue 画面遷移　呼び出し
        override func prepare(for segue: UIStoryboardSegue, sender:Any?){
            let inputViewController:InputViewController = segue.destination as! InputViewController

            if segue.identifier == "cellSegue" {
                let indexPath = self.tableView.indexPathForSelectedRow
                inputViewController.task = taskArray[indexPath!.row]
            } else {
                let task = Task()
                
                let allTasks = realm.objects(Task.self)
                if allTasks.count != 0 {
                    task.id = allTasks.max(ofProperty: "id")!+1
                }
                inputViewController.task = task
            }
        }
    
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            
            let task = taskArray[indexPath.row]
            
            cell.textLabel?.text = task.title
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString:String = formatter.string(from: task.date)
            cell.detailTextLabel?.text = dateString
            return cell
            
        }
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            performSegue(withIdentifier: "cellSegue", sender: nil)
        }
        func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
            return .delete
        }
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete{
                //削除するタスクを取得する
                let task = self.taskArray[indexPath.row]
                
                //ローカル通知をキャンセルする
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
                
                //データベースから削除
                try! realm.write{
                    self.realm.delete(self.taskArray[indexPath.row])
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
                //未通知のローカル通知一覧をログ出力
                center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                    for request in requests {
                        print("/---------")
                        print(request)
                        print("----------/")
                    }
                }
            }
        }
        // 入力画面から戻ってきた時に TableView を更新させる
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            tableView.reloadData()
        }
    }
