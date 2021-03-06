//
//  LoginViewController.swift
//  Ciberchat
//
//  Created by user182813 on 10/17/20.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
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
        field.backgroundColor = .secondarySystemBackground
        
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
        field.backgroundColor = .secondarySystemBackground
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
    
    private let loginGoogleButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .LogInNotificacion,
                                               object: nil,
                                               queue: .main,
                                               using: {[weak self] _ in
                                                guard let strongSelf = self else {
                                                    return
                                                }
                                                
                                                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                                               })
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        title = "Log In"
        view.backgroundColor = .systemBackground
        
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
        scrollView.addSubview(loginGoogleButton)

    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
        loginGoogleButton.frame = CGRect(x: 30, y: loginFBButton.bottom+10, width: scrollView.width-60, height: 52)
    }
    
    @objc private func dioClickLogin(){
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertaErrorLogin()
            return
        }
        
        spinner.show(in: view)
        
        //Firebase Login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self] authResult, error in
                      
            guard let strongSelf = self else{
                return
            }
            
            DispatchQueue.main.async{
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("Error al autenticar usuario con el email: \(email)")
                return
            }
            
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(email: email)
            DatabaseManager.shared.obtenerDataPara(path: safeEmail, completion: { resultado in
                switch resultado{
                case .success(let data):
                    guard let usuarioData = data as? [String: Any],
                          let nombre = usuarioData["nombres"],
                          let apellido = usuarioData["apellidos"] else {
                        return
                    }
                    UserDefaults.standard.set("\(nombre) \(apellido)", forKey: "nombre")
                case .failure(let error):
                    print("Fallo al leer la data \(error)")
                }
            })
            
            UserDefaults.standard.set(email, forKey: "email")
            
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
                                                        parameters: ["fields": "email, first_name, last_name, picture.type(large)"],
                                                        tokenString: token,
                                                        version: nil,
                                                        httpMethod: .get)
        facebookReques.start(completionHandler: {_, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Fallo al obtener datos de facebook")
                return
            }
            print("\(result)")
            
            guard let nombres = result["first_name"] as? String,
                  let apellidos = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else{
                print("Hubo un error al obtenet email y nombre de usuario de facebook")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(nombres) \(apellidos)", forKey: "nombre")
            
            DatabaseManager.shared.usuarioExiste(with: email, completion: { exists in
                if !exists {
                    let ciberchatUsuario = CiberchatUsuario(nombres: nombres, apellidos: apellidos, email: email)
                    DatabaseManager.shared.insertarUsuario(with: ciberchatUsuario, termino: {success in
                        if success {
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            URLSession.shared.dataTask(with: url, completionHandler: {data, _, _ in
                                guard let data = data else{
                                    return
                                }
                                
                                print("Descargando data de facebook")
                                //subir imagen
                                let nombreArchivo = ciberchatUsuario.fotoPerfilNombreArchivo
                                StorageManager.shared.subirImagenPerfil(with: data,
                                                                        nombreArchivo: nombreArchivo,
                                                                        termino: {resultados in
                                                                            switch resultados {
                                                                            case .success(let downloadUrl):
                                                                                UserDefaults.standard.set(downloadUrl, forKey: "perfil_imagen_url")
                                                                                print(downloadUrl)
                                                                            case .failure(let error):
                                                                                print("Sorage manager error: \(error)")
                                                                            }
                                                                        })
                            }).resume()
                        }
                    })
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
