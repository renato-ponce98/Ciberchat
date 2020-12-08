//
//  ConversacionTableViewCell.swift
//  Ciberchat
//
//  Created by user182813 on 11/15/20.
//

import UIKit
import SDWebImage

class ConversacionTableViewCell: UITableViewCell {
    
    static let identificador = "ConversacionTableViewCell"
    
    private let usuarioImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let usuarioNombreLabel: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let usuarioMensajeLabel: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(usuarioImageView)
        contentView.addSubview(usuarioNombreLabel)
        contentView.addSubview(usuarioMensajeLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        usuarioImageView.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        usuarioNombreLabel.frame = CGRect(x: usuarioImageView.right + 10, y: 10, width: contentView.width - 20 - usuarioImageView.width, height: (contentView.height - 20) / 2)
        usuarioMensajeLabel.frame = CGRect(x: usuarioImageView.right + 10, y: usuarioNombreLabel.bottom + 10, width: contentView.width - 20 - usuarioImageView.width, height: (contentView.height - 20) / 2)
    }
    
    public func configurar(with model: Conversacion){
        usuarioMensajeLabel.text = model.ultimoMensaje.texto
        usuarioNombreLabel.text = model.nombre
        
        let path = "images/\(model.otroUsuarioEmail)_perfil_imagen.png"
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
