//
//  PerfilViewController.swift
//  Ciberchat
//
//  Created by user182813 on 10/17/20.
//

import UIKit
import FirebaseAuth

class PerfilViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let data = ["Cerrar sesion"]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
    }

}

extension PerfilViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let actionSheet = UIAlertController(title: "",
                                      message: "",
                                      preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title:"Cerrar sesion",
                                      style: .destructive,
                                      handler: {[weak self] _ in
                                        
                                        guard let strongSelf = self else {
                                            return
                                        }
                                        
                                        do {
                                            try FirebaseAuth.Auth.auth().signOut()
                                            
                                            let vc = LoginViewController()
                                            let nav = UINavigationController(rootViewController: vc)
                                            nav.modalPresentationStyle = .fullScreen
                                            strongSelf.present(nav, animated: false)
                                        } catch  {
                                            print("Hubo un error al momento de Cerrar sesion")
                                        }
                                      }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancelar",
                                            style: .cancel,
                                            handler: nil))
        
        present(actionSheet, animated: true)
        
        
        
    }
}
