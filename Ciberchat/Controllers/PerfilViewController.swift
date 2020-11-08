//
//  PerfilViewController.swift
//  Ciberchat
//
//  Created by user182813 on 10/17/20.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class PerfilViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let data = ["Cerrar sesion"]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = crearTableHeader()
    }
    
    func crearTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let filename = safeEmail + "_perfil_imagen.png"
        
        let path = "images/"+filename
        
        let headerview = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        headerview.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (headerview.width-150) / 2, y: 75, width: 150, height: 150))
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.cornerRadius = imageView.width / 2
        imageView.layer.masksToBounds = true
        
        headerview.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] resultado in
            switch resultado {
            case .success(let url):
                self?.descargarImagen(imageView: imageView, url: url)
            case .failure(let error):
                print("Fallo al obtener url de descarga: \(error)")
            }
        })
        
        return headerview
    }
    
    func descargarImagen(imageView: UIImageView, url: URL){
        URLSession.shared.dataTask(with: url, completionHandler: {data, _ , error in
            guard let data = data, error == nil else {
                return
            }
            
            DispatchQueue.main.async{
                let image = UIImage(data: data)
                imageView.image = image
            }
        }).resume()
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
                                        
                                        // Cerrar sesion en facebook
                                        FBSDKLoginKit.LoginManager().logOut()
                                        
                                        // Cerrar sesion en google
                                        GIDSignIn.sharedInstance()?.signOut()
                                        
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
