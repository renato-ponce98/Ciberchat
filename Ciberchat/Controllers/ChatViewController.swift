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
    private var mensajes = [Message]()
    private var remitente : Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        return Sender(photoURL: "", senderId: email, displayName: "Joe Smith")
    }
    
    init(with email: String){
        self.otroUsuarioEmail = email
        super.init(nibName: nil, bundle: nil)
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
        
        print("Sigo aqui")
        //Enviar mensaje
        if esNuevaConversacion{
            let mensaje = Message(sender: remitente, messageId: mensajeId, sentDate: Date(), kind: .text(text))
            DatabaseManager.shared.crearNuevaConversacin(with: otroUsuarioEmail, primerMensaje: mensaje, completion: {success in
                if success {
                    print("Mensaje Enviado")
                }else{
                    print("Ocurrio un error al enviar el mensaje")
                }
            })
        }else{
            print("No realice nada")
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
        return Sender(photoURL: "", senderId: "123", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return mensajes[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return mensajes.count
    }
    
    
}
