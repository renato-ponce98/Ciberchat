//
//  ChatViewController.swift
//  Ciberchat
//
//  Created by user182813 on 10/25/20.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage

struct Message: MessageType{
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

extension MessageKind {
    var messagekindString:  String {
        switch self {
        
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType{
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    public var esNuevaConversacion = false
    public let otroUsuarioEmail: String
    private let conversacionId: String?
    private var mensajes = [Message]()
    private var remitente : Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Yo")
    }
    
    init(with email: String, id: String?){
        self.conversacionId = id
        self.otroUsuarioEmail = email
        super.init(nibName: nil, bundle: nil)
        if let conversacionId = conversacionId {
            escucharPorMensajes(id: conversacionId, debeScrollFinal: true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setearInputBoton()
    }
    
    private func setearInputBoton(){
        let boton = InputBarButtonItem()
        boton.setSize(CGSize(width: 35, height: 35), animated: false)
        boton.setImage(UIImage(systemName: "plus"), for: .normal)
        boton.onTouchUpInside { [weak self] _ in
            self?.presentarInputActionSheet()
        }
        
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([boton], forStack: .left, animated: false)
    }
    
    private func presentarInputActionSheet(){
        let actionSheet = UIAlertController(title: "Adjuntar Contenido", message: "Que te gustaria adjuntar?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Foto", style: .default, handler: {[weak self] _ in
            self?.presentarFotoInputActionsheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {_ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(actionSheet, animated: true )
    }
    
    private func presentarFotoInputActionsheet(){
        let actionSheet = UIAlertController(title: "Adjuntar Imagen", message: "De donde te gustaria adjuntar la foto?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camara", style: .default, handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Galeria", style: .default, handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)

        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(actionSheet, animated: true )
    }
    
    private func escucharPorMensajes(id: String, debeScrollFinal: Bool){
        DatabaseManager.shared.obtenerTodosMensajesParaConversacion(with: id, completion: { [weak self] resultado in
            switch resultado {
            case .success(let mensajes):
                guard !mensajes.isEmpty else {
                    return
                }
                self?.mensajes = mensajes
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if debeScrollFinal {
                        self?.messagesCollectionView.scrollToBottom()
                    }                }
            case .failure(let error):
                print("fallo al obtener mensajes: \(error)")
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }

}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let imagen = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
              let imagenData = imagen.pngData(),
              let mensajeId = crearMensajeId(),
              let conversacionId = conversacionId,
              let nombre = self.title,
              let remitente = remitente else {
            return
        }
        
        let nombreArchivo = "foto_mensaje_"+mensajeId.replacingOccurrences(of: " ", with: "-") + ".png"
        
        StorageManager.shared.subirImagenMensaje(with: imagenData, nombreArchivo: nombreArchivo, termino: {[weak self] resultado in
            guard let strongSelf = self else {
                return
            }
            switch resultado {
            case .success(let urlString):
                print("Imagen enviada: \(urlString)")
                
                guard let url = URL(string: urlString),
                      let placeholder = UIImage(systemName: "plus") else {
                    return
                }
                
                let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                
                let mensaje = Message(sender: remitente, messageId: mensajeId, sentDate: Date(), kind: .photo(media))
                DatabaseManager.shared.enviarMensaje(to: conversacionId, otroUsuarioEmail: strongSelf.otroUsuarioEmail, nombre: nombre, nuevoMensaje: mensaje, completion: {success in
                    if success {
                        print("se envio Imagen")
                    }else {
                        print("fallo al enviar mensaje")
                    }
                })
            case .failure(let error):
                print("Hubo un error al enviar la imagen \(error)")
            }
        })
        
        
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        print("Entre aqui")
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let remitente = self.remitente,
              let mensajeId = crearMensajeId() else {
            return
        }
        
        let mensaje = Message(sender: remitente, messageId: mensajeId, sentDate: Date(), kind: .text(text))

        //Enviar mensaje
        if esNuevaConversacion{
            
            DatabaseManager.shared.crearNuevaConversacin(with: otroUsuarioEmail, nombre: self.title ?? "Usuario", primerMensaje: mensaje, completion: { [weak self] success in
                if success {
                    print("Mensaje Enviado")
                    self?.esNuevaConversacion = false
                }else{
                    print("Ocurrio un error al enviar el mensaje")
                }
            })
        }else{
            print("No realice nada")
            guard let conversacionId = conversacionId,
                  let nombre = self.title else{
                return
            }
            DatabaseManager.shared.enviarMensaje(to: conversacionId, otroUsuarioEmail: otroUsuarioEmail, nombre: nombre, nuevoMensaje: mensaje, completion: {success in
                if success {
                    print("mensaje enviado")
                }else {
                    print("fallo al enviar")
                }
            })
        }
    }
    
    private func crearMensajeId() -> String?{
        guard let actualUsuarioEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeActualEmail = DatabaseManager.safeEmail(email: actualUsuarioEmail)
        
        let fechaString = Self.dateFormatter.string(from: Date())
        
        let nuevoIdentificador = "\(otroUsuarioEmail)_\(safeActualEmail)_\(fechaString)"
        
        return nuevoIdentificador
    }
}

extension ChatViewController:  MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = remitente{
            return sender
        }
        fatalError("El remitente es nulo")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return mensajes[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return mensajes.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let mensaje = message as? Message else {
            return
        }
        
        switch mensaje.kind {
        case .photo(let media):
            guard let imagenUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imagenUrl, completed: nil)
        default:
            break
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let mensaje = mensajes[indexPath.section]
        
        switch mensaje.kind {
        case .photo(let media):
            guard let imagenUrl = media.url else {
                return
            }
            let vc = VisualizadorFotoViewController(with: imagenUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
