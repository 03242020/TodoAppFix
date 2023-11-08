//
//  ViewController.swift
//  Todo
//
//  Created by ryo.inomata on 2023/07/12.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {

    @IBOutlet weak var registerEmailTextField: UITextField!
    @IBOutlet weak var registerPasswordTextField: UITextField!
    @IBOutlet weak var registerNameTextField: UITextField!
    @IBOutlet weak var loginEmailTextField: UITextField!
    @IBOutlet weak var loginPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func tapRegisterButton(_ sender: Any) {
        if let email = registerEmailTextField.text,
           let password = registerPasswordTextField.text,
           let name = registerNameTextField.text {
            // ①FirebaseAuthにemailとpasswordでアカウントを作成する
            Auth.auth().createUser(withEmail: email, password: password, completion: {(result, error) in
                if let user = result?.user {
                    print("ユーザー作成完了 uid" + user.uid)
                    // ②FirestoreのUsersコレクションにdocumentID = ログインしたuidでデータを作成する
                    Firestore.firestore().collection("users").document(user.uid).setData([
                        "name": name], completion: {
                            error in
                            //NHKツールで良く見たハンドラ
                            if let error = error {
                                // ②が失敗した場合
                                print("Firestore 新規登録失敗 " + error.localizedDescription)
                                let dialog = UIAlertController(title: "新規登録失敗", message: error.localizedDescription, preferredStyle: .alert)
                                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                self.present(dialog, animated: true, completion: nil)
                            } else {
                                print("ユーザー作成完了 name:" + name)
                                //③成功した場合はTodo一覧画面に画面遷移を行う, 強制アンラップ確認
                                let listStoryboard = UIStoryboard(name: "TodoListViewController", bundle: nil)
                                if let listVC = listStoryboard.instantiateViewController(withIdentifier: "List") as? TodoListViewController {
                                    listVC.modalPresentationStyle = .fullScreen
                                    self.present(listVC, animated: true, completion: nil)
                                }
//                                let storyboard: UIStoryboard = self.storyboard!
//                                let next = storyboard.instantiateViewController(withIdentifier: "TodoListViewController")
                            }
                        })
                } else if let error = error {
                    //①が失敗した場合
                    print("Firebase Auth 新規登録失敗 " + error.localizedDescription)
                    let dialog = UIAlertController(title: "新規登録失敗", message: error.localizedDescription, preferredStyle: .alert)
                    dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(dialog, animated: true, completion:  nil)
                }
            })
        }
    }
    
    @IBAction func tapLoginButton(_ sender: Any) {
        if let email = loginEmailTextField.text,
           let password = loginPasswordTextField.text {
            // ①FirebaseAuthにemailとpasswordでログインを行う
            Auth.auth().signIn(withEmail: email, password: password, completion: {(result, error) in
                if let user = result?.user {
                    print("ログイン完了 uid:" + user.uid)
                    // ②成功した場合はTodo一覧画面に画面遷移を行う
                    let listStoryboard = UIStoryboard(name: "TodoListViewController", bundle: nil)
                    if let listVC = listStoryboard.instantiateViewController(withIdentifier: "List") as? TodoListViewController {
                        listVC.modalPresentationStyle = .fullScreen
                        self.present(listVC, animated: true, completion: nil)
                    }
                } else if let error = error {
                    // ①が失敗した場合
                    print("ログイン失敗 " + error.localizedDescription)
                    let dialog = UIAlertController(title: "ログイン失敗", message: error.localizedDescription, preferredStyle: .alert)
                    dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(dialog, animated:  true, completion: nil)
                }
            })
        }
    }
}
