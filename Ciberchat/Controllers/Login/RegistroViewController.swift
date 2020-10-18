//
//  RegistroViewController.swift
//  Ciberchat
//
//  Created by user182813 on 10/17/20.
//

import UIKit

class RegistroViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Correo Electronico..."
        
        field.leftView = UIView(frame: CGRect(x:0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        
        return field
    }()
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        
        field.leftView = UIView(frame: CGRect(x:0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        
        return field
    }()
    private let nombresField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Ingrese sus nombres..."
        
        field.leftView = UIView(frame: CGRect(x:0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        
        return field
    }()
    private let apellidosField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Ingrese sus apellidos..."
        
        field.leftView = UIView(frame: CGRect(x:0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        
        return field
    }()
    private let RegistroButton: UIButton = {
        let button = UIButton()
        button.setTitle("Registrarse", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Registrate"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dioClickRegistrar))
        
        RegistroButton.addTarget(self, action: #selector(dioClickLogin), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(nombresField)
        scrollView.addSubview(apellidosField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(RegistroButton)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(dioClickCambiarImagen))
        gesture.numberOfTouchesRequired = 1
        gesture.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(gesture)
    }
    
    @objc private func dioClickCambiarImagen(){
        print("Cambiar iamgen seleccionada")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        nombresField.frame = CGRect(x: 30, y: imageView.bottom+10, width: scrollView.width-60, height: 52)
        apellidosField.frame = CGRect(x: 30, y: nombresField.bottom+10, width: scrollView.width-60, height: 52)
        emailField.frame = CGRect(x: 30, y: apellidosField.bottom+10, width: scrollView.width-60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom+10, width: scrollView.width-60, height: 52)
        RegistroButton.frame = CGRect(x: 30, y: passwordField.bottom+10, width: scrollView.width-60, height: 52)
    }
    
    @objc private func dioClickLogin(){
        nombresField.resignFirstResponder()
        apellidosField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let nombres = nombresField.text,
              let apellidos = apellidosField.text,
              let email = emailField.text,
              let password = passwordField.text,
              !nombres.isEmpty,
              !apellidos.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              password.count >= 6
        else {
            alertaErrorRegistro()
            return
        }
        
        //Firebase Login
    }
    
    func alertaErrorRegistro(){
        let alerta = UIAlertController(title: "Error en Registro",
                                       message: "Porfavor, ingrese la informacion necesaria para crear su cuenta.",
                                       preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "Cerrar", style: .cancel, handler: nil))
        present(alerta, animated: true)
    }

    @objc private func dioClickRegistrar(){
        let vc = RegistroViewController()
        vc.title = "Crear Cuenta"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension RegistroViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField{
            passwordField.becomeFirstResponder()
        }
        else if textField==passwordField{
            dioClickLogin()
        }
        return true
    }
}
