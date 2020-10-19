//
//  ViewController.swift
//  Ciberchat
//
//  Created by user182813 on 10/17/20.
//

import UIKit
import FirebaseAuth

class ConversacionesViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validarAutenticacion()
    }
    
    private func validarAutenticacion(){
        if FirebaseAuth.Auth.auth().currentUser == nil{
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    

}

