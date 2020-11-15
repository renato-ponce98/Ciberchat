//
//  ViewController.swift
//  Ciberchat
//
//  Created by user182813 on 10/17/20.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

struct Conversacion{
    let id: String
    let nombre: String
    let otroUsuarioEmail: String
    let ultimoMensaje: UltimoMensaje
}

struct UltimoMensaje{
    let fecha: String
    let texto: String
    let visto: Bool
}

class ConversacionesViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversaciones = [Conversacion]()
    
    private let tableView: UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(ConversacionTableViewCell.self,
                       forCellReuseIdentifier: ConversacionTableViewCell.identificador)
        return table
    }()
    
    private let noConversacionesLabel: UILabel = {
        let label = UILabel()
        label.text = "No tiene Conversaciones!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(dioClickComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversacionesLabel)
        setearTableView()
        recuperarConversaciones()
        empezarEscucharConversaciones()
    }
    
    private func empezarEscucharConversaciones(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        
        DatabaseManager.shared.obtenerTodasConversaciones(for: safeEmail, completion: { [weak self] resultado in
            switch resultado{
            case .success(let conversaciones):
                guard !conversaciones.isEmpty else {
                    return
                }
                self?.conversaciones = conversaciones
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("Error al obtener: \(error)")
            }
        })
    }
    
    @objc private func dioClickComposeButton(){
        let vc = NuevaConversacionViewController()
        vc.completion = { [weak self] resultado in
            self?.crearNuevaConversacion(resultado: resultado)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func crearNuevaConversacion(resultado: [String: String]){
        guard let nombre = resultado["nombre"],
              let email = resultado["email"] else {
            return
        }
              
        let vc = ChatViewController(with: email, id: nil)
        vc.esNuevaConversacion = true
        vc.title = nombre
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
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
    
    private func setearTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func recuperarConversaciones(){
        tableView.isHidden = false
    }
}

extension ConversacionesViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversaciones.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversaciones[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversacionTableViewCell.identificador, for: indexPath) as! ConversacionTableViewCell
        cell.configurar(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversaciones[indexPath.row]
        
        let vc = ChatViewController(with: model.otroUsuarioEmail, id: model.id)
        vc.title = model.nombre
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
