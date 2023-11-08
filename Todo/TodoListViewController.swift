//
//  TodoListViewController.swift
//  Todo
//
//  Created by ryo.inomata on 2023/07/13.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

//やること
//年の追加(ピッカビューの月と日の左側)
//カテゴリは最後にする
//updatedAtの下にカテゴリを4つほど追加する
//Todoカテゴリ分けてTodoを保存
//カテゴリでfirebase内でグループ化して、getする時にカテゴリも取得して、表示する。
//updatedAtが作成日日時になってしまっているので更新日にしっかり直す
//更新日は下に改める。

//UI調整ボタンの背景色を色変える
//レイアウト横ずれあり。修正必須。時間とか。
//日付と時間を項目を追加してそれらの選択が
//カテゴリの選択を1つまでにする。以前選んでたものが非活性化とする。
//カテゴリを列挙型を使って数字で判断する。
//下は後ほど行う。上を優先して行う。
//TodoModelを追加してId,Title,Detail...を設定して、Modelが配列となる。現状VとCはある。
//上記実装により、コード量が減る。
//
class TodoListViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet var buttons: [UIButton]!
    var getTodoArray: [TodoInfo] = [TodoInfo]()
    var lightBlue: UIColor { return UIColor.init(red: 186 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1.0) }
    // 画面下部の未完了、完了済みを判定するフラグ(falseは未完了)
    var isDone: Bool? = false
    enum CategoryType: Int {
        case normal     = 0
        case just       = 1
        case remember   = 2
        case either     = 3
        case toBuy      = 4
    }
    var viewType = CategoryType.normal.rawValue

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        configureRefreshControl()
        // Do any additional setup after loading the view.
    }
    //     モーダルから戻ってきた時はviewWillAppear(:)が呼ばれる
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        // ①ログイン済みかどうか確認
        if let user = Auth.auth().currentUser {
            // ②ログインしているユーザー名の取得
            Firestore.firestore().collection("users").document(user.uid).getDocument(completion: {(snapshot,error) in
                if let snap = snapshot {
                    if let data = snap.data() {
                        self.userNameLabel.text = data["name"] as? String
                    }
                } else if let error = error {
                    print("ユーザー名取得失敗: " + error.localizedDescription)
                }
            })
            if self.viewType == 0 {
                paintButton()
                getTodoDataForFirestore()
            } else {
                getTodoCategoryDataForFirestore()
            }
        }
    }
            /*Firestore.firestore().collection("users/\(user.uid)/todos").whereField("isDone", isEqualTo: isDone).order(by: "createdAt").addSnapshotListener({ (querySnapshot, error) in*/
                // ↑不具合の原因となったAPI記述
                // ↓全さんに修正して頂いたAPI記述
                /*Firestore.firestore().collection("users/\(user.uid)/todos").whereField("isDone", isEqualTo: isDone).order(by: "createdAt").getDocuments(completion:{ (querySnapshot, error) in*/
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getTodoArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = getTodoArray[indexPath.row].todoTitle
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let editStoryboard = UIStoryboard(name: "TodoEditViewController", bundle: nil)
        if let editVC = editStoryboard.instantiateViewController(withIdentifier: "Edit") as? TodoEditViewController {
            editVC.todoInfo = getTodoArray[indexPath.row]
            editVC.modalPresentationStyle = .fullScreen
            self.present(editVC, animated: true, completion: nil)
        }
    }
    // スワイプ時のアクションを設定するメソッド
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal,
                                            title: "Edit",
                                            handler: {(action: UIContextualAction, view: UIView, completion: (Bool) -> Void) in
            if let user = Auth.auth().currentUser {
                Firestore.firestore().collection("users/\(user.uid)/todos").document(self.getTodoArray[indexPath.row].todoId!).updateData(
                    [
                        "isDone": !self.getTodoArray[indexPath.row].todoIsDone!,
                        "updatedAt": FieldValue.serverTimestamp()
                    ]
                    , completion: { error in
                        if let error = error {
                            print("TODO更新失敗: " + error.localizedDescription)
                            let dialog = UIAlertController(title: "TODO更新失敗", message: error.localizedDescription, preferredStyle: .alert)
                            dialog.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(dialog, animated: true, completion: nil)
                        } else {
                            print("TODO更新成功")
                        }
                    })
            }
        })
        editAction.backgroundColor = UIColor(red: 101/255.0, green: 198/255.0, blue: 187/255.0, alpha: 1)
        // controlの値によって表示するアイコンを切り替え
        switch isDone {
        case true:
            editAction.image = UIImage(systemName: "arrowshape.turn.up.left")
        default:
            editAction.image = UIImage(systemName: "checkmark")
        }
        
        // 削除のスワイプ
        let deleteAction = UIContextualAction(style: .normal, title: "Delete", handler: { (action: UIContextualAction, view:UIView, completion: (Bool) -> Void) in
            if let user = Auth.auth().currentUser {
                Firestore.firestore().collection("users/\(user.uid)/todos").document(self.getTodoArray[indexPath.row].todoId!).delete(){ error in
                    if let error = error {
                        print("TODO削除失敗: " + error.localizedDescription)
                        let dialog = UIAlertController(title: "TODO削除失敗", message: error.localizedDescription, preferredStyle: .alert)
                        dialog.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(dialog, animated: true, completion: nil)
                    } else {
                        print("TODO削除成功")
                    }
                }
            }
        })
        deleteAction.backgroundColor = UIColor(red: 214/255.0, green: 69/255.0, blue: 65/255.0, alpha: 1)
        deleteAction.image = UIImage(systemName: "clear")
        
        // スワイプアクションを追加
        let swipeActionConfig = UISwipeActionsConfiguration(actions: [editAction, deleteAction])
        // fullスワイプ時に挙動が起きない様に制御
        swipeActionConfig.performsFirstActionWithFullSwipe = false
        
        return swipeActionConfig
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    @IBAction func tapAddButton(_ sender: Any) {
        // ①Todo作成画面に画面遷移
        let addStoryboard = UIStoryboard(name: "TodoAddViewController", bundle: nil)
        if let addVC = addStoryboard.instantiateViewController(withIdentifier: "Add") as? TodoAddViewController {
            addVC.modalPresentationStyle = .fullScreen
            self.present(addVC, animated: true, completion: nil)
        }
    }
    //
    @IBAction func tapLogoutButton(_ sender: Any) {
        // ①ログイン済みかどうか確認
        if Auth.auth().currentUser != nil {
            // ②ログアウトの処理
            do {
                try Auth.auth().signOut()
                print("ログアウト完了")
                // ③成功した場合はログイン画面へ遷移
                let storyboard: UIStoryboard = self.storyboard!
                let next = storyboard.instantiateViewController(withIdentifier: "ViewController")
                self.present(next, animated: true, completion: nil)
            } catch let error as NSError {
                print("ログアウト失敗:" + error.localizedDescription)
                // ②が失敗した場合
                let dialog = UIAlertController(title: "ログアウト失敗", message: error.localizedDescription, preferredStyle: .alert)
                dialog.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(dialog, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func changeDoneControl(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            isDone = false
        case 1:
            isDone = true
            // ないとエラーになるので定義している
        default:
            break
        }
        switchGetTodoDataFirestore()
    }
    
    @IBAction func tapCommonButton(_ sender: Any) {
        let tag = (sender as AnyObject).tag
                
        guard let tag = tag else {
            print("タグが設定されていません")
            return
        }
        viewType = tag
        let button = buttons.filter { $0.tag == tag }.first!
        clearButton()
        button.configuration?.background.backgroundColor = lightBlue
        button.tintColor = UIColor.white
        button.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 13, weight: .bold)
            return outgoing
        }
        switch tag {
        case 0:
            getTodoDataForFirestore()
        default:
            getTodoCategoryDataForFirestore()
        }
    }
    
    func paintButton() {
        //共通化できそう
        clearButton()
        let button = buttons.filter { $0.tag == viewType }.first!
        button.configuration?.background.backgroundColor = lightBlue
        button.tintColor = UIColor.white
        button.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 13, weight: .bold)
                return outgoing
            }
        print(type(of: viewType))
    }
    func clearButton() {
        for button in buttons {
            button.configuration?.background.backgroundColor = UIColor.white
            button.tintColor = .none
            button.configuration?.titleTextAttributesTransformer = .none
        }
    }
    // FirestoreからTodoを取得する処理
    func getTodoDataForFirestore() {
        getTodoArray = [TodoInfo]()
        if let user = Auth.auth().currentUser {
            Firestore.firestore().collection("users/\(user.uid)/todos").whereField("isDone", isEqualTo: isDone ?? false).order(by: "createdAt").getDocuments(completion: { (querySnapshot, error) in
                if let error = error {
                    print("TODO取得失敗: " + error.localizedDescription)
                } else {
                    if let querySnapshot = querySnapshot {
                        for doc in querySnapshot.documents {
                            let data = doc.data()
                            let todoId = doc.documentID
                            let todoTitle = data["title"] as? String
                            let todoDetail = data["detail"] as? String
                            let todoIsDone = data["isDone"] as? Bool
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            let todoCreatedTimestamp = data["createdAt"] as? Timestamp
                            let todoCreatedDate = todoCreatedTimestamp?.dateValue()
                            let todoCreatedString = dateFormatter.string(from: todoCreatedDate ?? Date())
                            print("Date: ",Date())
                            let todoUpdatedTimestamp = data["updatedAt"] as? Timestamp
                            let todoUpdatedDate = todoUpdatedTimestamp?.dateValue()
                            let todoUpdatedString = dateFormatter.string(from: todoUpdatedDate ?? Date())
                            let todoScheduleDate = data["scheduleDate"] as? String ?? "yyyy/mm/dd"
                            let todoScheduleTime = data["scheduleTime"] as? String ?? "hh:mm"
                            let todoViewType = data["viewType"] as? Int ?? 0
                            var newTodo = TodoInfo()
                            newTodo = TodoInfo(todoId: todoId,todoTitle: todoTitle,todoDetail: todoDetail,todoIsDone: todoIsDone,todoCreated: todoCreatedString,todoUpdated: todoUpdatedString, todoScheduleDate: todoScheduleDate,todoScheduleTime: todoScheduleTime,todoViewType: todoViewType)
                            self.getTodoArray.append(newTodo)
                            // オプショナル型にして、String以外の場合は、固定値を入れる記述。
                            // 強制アンラップは極力やめる
                            // 必須の要素はas!強制をする。あるかないか、scheduleDateArray等
                            // はオプショナル型の使用を推奨
                            // クラッシュの原因は大きい割合で、強制アンラップがありうるので気を付ける。
                            // Swift入門53Pあたりのオプショナルを読み直す
                            //scheduleDateArray?.append(data["scheduleDate"] as? String ?? "yyyy/mm/dd hh:mm")
                        }
                        self.tableView.reloadData()
                    }
                }
            })
        }
    }
    // FirestoreからTodoを取得する処理
    func getTodoCategoryDataForFirestore() {
        getTodoArray = [TodoInfo]()
        if let user = Auth.auth().currentUser {
            Firestore.firestore().collection("users/\(user.uid)/todos").whereField("viewType", isEqualTo: viewType).order(by: "createdAt").whereField("isDone", isEqualTo: isDone ?? false).getDocuments(completion: { (querySnapshot, error) in
                if let error = error {
                    print("TODO取得失敗: " + error.localizedDescription)
                } else {
                    if let querySnapshot = querySnapshot {
                        for doc in querySnapshot.documents {
                            let data = doc.data()
                            let todoId = doc.documentID
                            let todoTitle = data["title"] as? String
                            let todoDetail = data["detail"] as? String
                            let todoIsDone = data["isDone"] as? Bool
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            let todoCreatedTimestamp = data["createdAt"] as? Timestamp
                            let todoCreatedDate = todoCreatedTimestamp?.dateValue()
                            let todoCreatedString = dateFormatter.string(from: todoCreatedDate ?? Date())
                            print("Date: ",Date())
                            let todoUpdatedTimestamp = data["updatedAt"] as? Timestamp
                            let todoUpdatedDate = todoUpdatedTimestamp?.dateValue()
                            let todoUpdatedString = dateFormatter.string(from: todoUpdatedDate ?? Date())
                            let todoScheduleDate = data["scheduleDate"] as? String ?? "yyyy/mm/dd"
                            let todoScheduleTime = data["scheduleTime"] as? String ?? "hh:mm"
                            let todoViewType = data["viewType"] as? Int ?? 0
                            var newTodo = TodoInfo()
                            newTodo = TodoInfo(todoId: todoId,todoTitle: todoTitle,todoDetail: todoDetail,todoIsDone: todoIsDone,todoCreated: todoCreatedString,todoUpdated: todoUpdatedString, todoScheduleDate: todoScheduleDate,todoScheduleTime: todoScheduleTime,todoViewType: todoViewType)
                            self.getTodoArray.append(newTodo)
                            // オプショナル型にして、String以外の場合は、固定値を入れる記述。
                            // 強制アンラップは極力やめる
                            // 必須の要素はas!強制をする。あるかないか、scheduleDateArray等
                            // はオプショナル型の使用を推奨
                            // クラッシュの原因は大きい割合で、強制アンラップがありうるので気を付ける。
                            // Swift入門53Pあたりのオプショナルを読み直す
                            //scheduleDateArray?.append(data["scheduleDate"] as? String ?? "yyyy/mm/dd hh:mm")
                        }
                        self.tableView.reloadData()
                    }
                }
            })
        }
    }
    
    func switchGetTodoDataFirestore() {
        if viewType == 0 {
            getTodoDataForFirestore()
        } else {
            getTodoCategoryDataForFirestore()
        }
    }
    
    func configureRefreshControl() {
        //RefreshControlを追加する処理
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        switchGetTodoDataFirestore()
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
            self.view.endEditing(true)
        }
    }
}
