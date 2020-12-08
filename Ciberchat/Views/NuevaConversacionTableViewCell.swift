//
//  NuevaConversacionTableViewCell.swift
//  Ciberchat
//
//  Created by user182813 on 11/23/20.
//

import Foundation
import SDWebImage

class NuevaConversacionCell: UITableViewCell {
    
    static let identificador = "NuevaConversacionCell"
    
    private let usuarioImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 25
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let usuarioNombreLabel: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(usuarioImageView)
        contentView.addSubview(usuarioNombreLabel)    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        usuarioImageView.frame = CGRect(x: 10, y: 10, width: 50, height: 50)
        usuarioNombreLabel.frame = CGRect(x: usuarioImageView.right + 10, y: 20, width: contentView.width - 20 - usuarioImageView.width, height: 50)
        
    }
    
    public func configurar(with model: BuscarResultado){
        usuarioNombreLabel.text = model.nombre
        
        let path = "images/\(model.email)_perfil_imagen.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] resultado in
            switch resultado {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.usuarioImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("fallo al obtener url imagen: \(error)")
            }
        })
    }

}
