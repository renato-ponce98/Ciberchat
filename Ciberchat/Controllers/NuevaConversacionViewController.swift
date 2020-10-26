//
//  NuevaConversacionViewController.swift
//  Ciberchat
//
//  Created by user182813 on 10/17/20.
//

import UIKit
import JGProgressHUD

class NuevaConversacionViewController: UIViewController {
    private let spinner = JGProgressHUD()
    
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
        barraBusqueda.delegate = self
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = barraBusqueda
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancelar",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(cerrar))
        barraBusqueda.becomeFirstResponder()
    }
    
    @objc private func cerrar(){
        dismiss(animated: true, completion: nil)
    }
    
}

extension NuevaConversacionViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
}
