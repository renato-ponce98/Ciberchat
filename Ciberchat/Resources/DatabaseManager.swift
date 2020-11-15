//
//  DatabaseManager.swift
//  Ciberchat
//
//  Created by user182813 on 10/19/20.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(email: String) -> String{
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

extension DatabaseManager{
    public func usuarioExiste(with email: String,
                              completion: @escaping ((Bool) -> Void)){
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    ///Inserta a un nuevo usuario a la Base de datos
    public func insertarUsuario(with user: CiberchatUsuario, termino: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
                                                "nombres":user.nombres,
                                                "apellidos":user.apellidos
        ], withCompletionBlock: {error, _ in
            guard error == nil else {
                print("Fallo al escribir en la BD")
                termino(false)
                return
            }
            
            self.database.child("usuarios").observeSingleEvent(of: .value, with: { snapshot in
                if var coleccionUsuarios = snapshot.value as? [[String:String]] {
                    let newElement = [
                        "nombre": user.nombres + " " + user.apellidos,
                        "email": user.safeEmail
                    ]
                    coleccionUsuarios.append(newElement)
                    
                    self.database.child("usuarios").setValue(coleccionUsuarios, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            termino(false)
                            return
                        }
                        termino(true)
                    })
                }else {
                    let nuevaColeccion: [[String : String]] = [
                        [
                            "nombre": user.nombres + " " + user.apellidos,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("usuarios").setValue(nuevaColeccion, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            termino(false)
                            return
                        }
                        termino(true)
                    })
                }
            })
        })
    }
    public func obtenerUsuarios(completion: @escaping (Result<[[String: String]], Error>) -> Void){
        database.child("usuarios").observeSingleEvent(of: .value, with: {snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.falloAlObtener))
                return
            }
            
            completion(.success(value))
        })
    }
    
    public enum DatabaseError: Error {
        case falloAlObtener
    }
}

//Enviar mensajes / conversaciones

extension DatabaseManager {
    public func crearNuevaConversacin(with otroUsuarioEmail: String, primerMensaje: Message, completion: @escaping (Bool) -> Void){
        guard let actualEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: actualEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: {snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("usuario no encontrado")
                return
            }
            
            let mensajeFecha = primerMensaje.sentDate
            let fechaString = ChatViewController.dateFormatter.string(from: mensajeFecha)
            
            var mensaje = ""
            
            switch primerMensaje.kind {
            case .text(let mensajeTexto):
                mensaje = mensajeTexto
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversacionID = "conversation_\(primerMensaje.messageId)"
            
            let nuevaConversacionData: [String: Any] = [
                "id": conversacionID,
                "otro_usuario_email": otroUsuarioEmail,
                "ultimo_mensaje":[
                    "fecha": fechaString,
                    "mensaje": mensaje,
                    "visto": false
                ]
            ]
            
            if var conversaciones = userNode["conversaciones"] as? [[String: Any]]{
                conversaciones.append(nuevaConversacionData)
                userNode["conversaciones"] = conversaciones
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.terminarCrearConversacion(conversacionID: conversacionID, primerMensaje: primerMensaje, completion: completion)
                 })
            }else {
                userNode["conversaciones"] = [
                    nuevaConversacionData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.terminarCrearConversacion(conversacionID: conversacionID, primerMensaje: primerMensaje, completion: completion)
                 })
            }
            
        })
        
    }
    
    private func terminarCrearConversacion(conversacionID: String, primerMensaje: Message, completion: @escaping (Bool) -> Void){
        
        let mensajeFecha = primerMensaje.sentDate
        let fechaString = ChatViewController.dateFormatter.string(from: mensajeFecha)
        
        var mensaje = ""
        
        switch primerMensaje.kind {
        case .text(let mensajeTexto):
            mensaje = mensajeTexto
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let miEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let actualUsuarioEmail = DatabaseManager.safeEmail(email: miEmail)
        
        let coleccionMensaje: [String: Any] = [
            "id": primerMensaje.messageId,
            "tipo": primerMensaje.kind.messagekindString,
            "contenido": mensaje,
            "fecha": fechaString,
            "remitente_email": actualUsuarioEmail,
            "visto": false
        ]
        
        let value: [String: Any] = [
            "mensajes":[
                coleccionMensaje
            ]
        ]
        
        database.child("\(conversacionID)").setValue(value, withCompletionBlock: {error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    public func obtenerTodasConversaciones(for email: String, completion: @escaping (Result<String, Error>) -> Void){
        
    }
    
    public func obtenerTodosMensajesParaConversacion(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    public func enviarMensaje(to conversacion: String, mensaje: Message, completion: @escaping (Bool) -> Void){
        
    }
}

struct CiberchatUsuario{
    let nombres: String
    let apellidos: String
    let email: String
    
    var safeEmail: String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var fotoPerfilNombreArchivo: String {
        return "\(safeEmail)_perfil_imagen.png"
    }
}
