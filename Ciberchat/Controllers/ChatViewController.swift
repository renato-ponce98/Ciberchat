//
//  ChatViewController.swift
//  Ciberchat
//
//  Created by user182813 on 10/25/20.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType{
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
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
        messageInputBar.delegate = self
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
    
    
}
