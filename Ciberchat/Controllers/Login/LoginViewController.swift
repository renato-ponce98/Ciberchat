//
//  LoginViewController.swift
//  Ciberchat
//
//  Created by user182813 on 10/17/20.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit

class LoginViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "loginImg")
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
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let loginFBButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email, public_profile"]
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dioClickRegistrar))
        
        loginButton.addTarget(self, action: #selector(dioClickLogin), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        loginFBButton.delegate = self
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(loginFBButton)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/1.5
        imageView.frame = CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom+10, width: scrollView.width-60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom+10, width: scrollView.width-60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom+10, width: scrollView.width-60, height: 52)
        loginFBButton.frame = CGRect(x: 30, y: loginButton.bottom+10, width: scrollView.width-60, height: 52)
    }
    
    @objc private func dioClickLogin(){
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertaErrorLogin()
            return
        }
        
        //Firebase Login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self] authResult, error in
            guard let strongSelf = self else{
                return
            }
            guard let result = authResult, error == nil else {
                print("Error al autenticar usuario con el email: \(email)")
                return
            }
            
            let user = result.user
            print("Usuario Autenticado: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    func alertaErrorLogin(){
        let alerta = UIAlertController(title: "Error en Log in",
                                       message: "Porfavor, ingrese la informacion correcta.",
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

extension LoginViewController: UITextFieldDelegate{
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

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //
    }
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else{
            print("Hubo un error al iniciar sesion con Facebook")
            return
        }
        
        let facebookReques = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                        parameters: ["fields": "email, name"],
                                                        tokenString: token,
                                                        version: nil,
                                                        httpMethod: .get)
        facebookReques.start(completionHandler: {_, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Fallo al obtener datos de facebook")
                return
            }
            print("\(result)")
            
            
            guard let nombreUsuario = result["name"] as? String,
                  let email = result["email"] as? String else{
                print("Hubo un error al obtenet email y nombre de usuario de facebook")
                return
            }
            
            let nombreComponents = nombreUsuario.components(separatedBy: " ")
            guard nombreComponents.count == 3 else {
                return
            }
            
            let nombres = nombreComponents[0]
            let apellidos = nombreComponents[1]
            
            DatabaseManager.shared.usuarioExiste(with: email, completion: { exists in
                if !exists {
                    DatabaseManager.shared.insertarUsuario(with: CiberchatUsuario(nombres: nombres, apellidos: apellidos, email: email))
                }
            })
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: {[weak self] authResult, error in
                guard let strongSelf = self else{
                    return
                }
                guard authResult != nil, error == nil else {
                    print("Inicio de sesion con facebook fallida.")
                    return
                }
                
                print("Inicio de sesion exitoso")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
}
