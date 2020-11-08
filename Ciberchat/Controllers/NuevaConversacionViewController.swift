//
//  NuevaConversacionViewController.swift
//  Ciberchat
//
//  Created by user182813 on 10/17/20.
//

import UIKit
import JGProgressHUD

class NuevaConversacionViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    
    private var usuarios = [[String: String]]()
    private var resultados = [[String: String]]()
    private var hasFetched = false
    
    private let barraBusqueda: UISearchBar = {
        let barraBusqueda = UISearchBar()
        barraBusqueda.placeholder = "Buscar Usuario ..."
        return barraBusqueda
    }()

    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResultadoLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No hay resultados"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResultadoLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        barraBusqueda.delegate = self
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = barraBusqueda
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancelar",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(cerrar))
        barraBusqueda.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultadoLabel.frame = CGRect(x: view.width / 4, y: (view.height-200) / 2, width: view.width / 2, height: 200)
    }
    
    @objc private func cerrar(){
        dismiss(animated: true, completion: nil)
    }
    
}

extension NuevaConversacionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultados.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = resultados[indexPath.row]["nombre"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension NuevaConversacionViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        resultados.removeAll()
        spinner.show(in: view)
        
        self.searchUsers(query: text)
    }
    
    func searchUsers(query: String){
        if hasFetched{
            filtrarUsuarios(with: query)
        }else{
            DatabaseManager.shared.obtenerUsuarios(completion: { [weak self] resultado in
                switch resultado {
                case .success(let coleccionUsuarios):
                    self?.hasFetched = true
                    self?.usuarios = coleccionUsuarios
                    self?.filtrarUsuarios(with: query)
                case .failure(let error):
                    print("fallo al obtener usuarios: \(error)")
                }
            })
        }
    }
    
    func filtrarUsuarios(with term: String){
        guard hasFetched else {
            return
        }
        
        self.spinner.dismiss()
        
        let resultados: [[String: String]] =  self.usuarios.filter({
            guard let name = $0["nombre"]?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        })
        
        self.resultados = resultados
        
        actualizarUI()
    }
    
    func actualizarUI() {
        if resultados.isEmpty {
            self.noResultadoLabel.isHidden = false
            self.tableView.isHidden = true
            
        }else{
            self.noResultadoLabel.isHidden = false
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}
