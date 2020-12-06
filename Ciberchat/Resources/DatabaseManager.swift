//
//  DatabaseManager.swift
//  Ciberchat
//
//  Created by user182813 on 10/19/20.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation
final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(email: String) -> String{
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

extension DatabaseManager {
    public func obtenerDataPara(path: String, completion: @escaping (Result<Any,Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.falloAlObtener))
                return
            }
            completion(.success(value))
        })
    }
}

extension DatabaseManager{
    public func usuarioExiste(with email: String,
                              completion: @escaping ((Bool) -> Void)){
        let safeEmail = DatabaseManager.safeEmail(email: email)
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard snapshot.value as? [String: Any] != nil else{
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
    public func crearNuevaConversacin(with otroUsuarioEmail: String, nombre: String, primerMensaje: Message, completion: @escaping (Bool) -> Void){
        guard let actualEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let actualnombre = UserDefaults.standard.value(forKey: "nombre") as? String else{
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: actualEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
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
                "nombre": nombre,
                "ultimo_mensaje":[
                    "fecha": fechaString,
                    "mensaje": mensaje,
                    "visto": false
                ]
            ]
            
            let destinatario_nuevaConversacionData: [String: Any] = [
                "id": conversacionID,
                "otro_usuario_email": safeEmail,
                "nombre": actualnombre,
                "ultimo_mensaje":[
                    "fecha": fechaString,
                    "mensaje": mensaje,
                    "visto": false
                ]
            ]
            
            //Actualizar destinatario
            self?.database.child("\(otroUsuarioEmail)/conversaciones").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversaciones = snapshot.value as? [[String: Any]]{
                    conversaciones.append(destinatario_nuevaConversacionData)
                    self?.database.child("\(otroUsuarioEmail)/conversaciones").setValue(conversaciones)
                }else {
                    self?.database.child("\(otroUsuarioEmail)/conversaciones").setValue([destinatario_nuevaConversacionData])
                }
            })
            
            
            // Actualizar usuario actual
            if var conversaciones = userNode["conversaciones"] as? [[String: Any]]{
                conversaciones.append(nuevaConversacionData)
                userNode["conversaciones"] = conversaciones
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.terminarCrearConversacion(nombre: nombre, conversacionID: conversacionID, primerMensaje: primerMensaje, completion: completion)
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
                    
                    self?.terminarCrearConversacion(nombre: nombre, conversacionID: conversacionID, primerMensaje: primerMensaje, completion: completion)
                 })
            }
            
        })
        
    }
    
    private func terminarCrearConversacion(nombre: String, conversacionID: String, primerMensaje: Message, completion: @escaping (Bool) -> Void){
        
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
            "visto": false,
            "nombre": nombre
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
    
    public func obtenerTodasConversaciones(for email: String, completion: @escaping (Result<[Conversacion], Error>) -> Void){
        database.child("\(email)/conversaciones").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.falloAlObtener))
                return
            }
            
            let conversaciones: [Conversacion] = value.compactMap({ diccionario in
                guard let conversacionId = diccionario["id"] as? String,
                      let nombre = diccionario["nombre"] as? String,
                      let otroUsuarioEmail = diccionario["otro_usuario_email"] as? String,
                      let ultimoMensaje = diccionario["ultimo_mensaje"] as? [String: Any],
                      let fecha = ultimoMensaje["fecha"] as? String,
                      let mensaje = ultimoMensaje["mensaje"] as? String,
                      let visto = ultimoMensaje["visto"] as? Bool else {
                        return nil
                }
                
                let ultimoMensajeObject = UltimoMensaje(fecha: fecha, texto: mensaje, visto: visto)
                
                return Conversacion(id: conversacionId, nombre: nombre, otroUsuarioEmail: otroUsuarioEmail, ultimoMensaje: ultimoMensajeObject)
            })
            
            completion(.success(conversaciones))
        })
    }
    
    public func obtenerTodosMensajesParaConversacion(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/mensajes").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.falloAlObtener))
                return
            }
            
            let mensajes: [Message] = value.compactMap({ diccionario in
                guard let nombre = diccionario["nombre"] as? String,
                      let visto = diccionario["visto"] as? Bool,
                      let mensajeId = diccionario["id"] as? String,
                      let contenido = diccionario["contenido"] as? String,
                      let remitenteEmail = diccionario["remitente_email"] as? String,
                      let tipo = diccionario["tipo"] as? String,
                      let fechaString = diccionario["fecha"] as? String,
                      let fecha = ChatViewController.dateFormatter.date(from: fechaString) else {
                        return nil
                }
                
                var kind: MessageKind?
                if tipo == "photo"{
                    guard let imageUrl = URL(string: contenido),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: imageUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }else if tipo == "video"{
                    guard let videoUrl = URL(string: contenido),
                          let placeholder = UIImage(named: "video_placeholder") else {
                        return nil
                    }
                    let media = Media(url: videoUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                else if tipo == "location"{
                    let locationComponents = contenido.components(separatedBy: ",")
                    guard let longitud = Double(locationComponents[0]),
                          let latitud = Double(locationComponents[1]) else{
                        return nil
                    }
                    
                    let location = Location(location: CLLocation(latitude: latitud, longitude: longitud), size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                }
                else{
                    kind = .text(contenido)
                }
                
                guard let finalkind = kind else {
                    return nil
                }
                
               let remitente = Sender(photoURL: "", senderId: remitenteEmail, displayName: nombre)
                
                return Message(sender: remitente, messageId: mensajeId, sentDate: fecha, kind: finalkind)
            })
            
            completion(.success(mensajes))
        })
    }
    
    public func enviarMensaje(to conversacion: String, otroUsuarioEmail: String, nombre: String, nuevoMensaje: Message, completion: @escaping (Bool) -> Void){
        
        guard let miEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let actualEmail = DatabaseManager.safeEmail(email: miEmail)
        
        database.child("\(conversacion)/mensajes").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            guard var actualMensajes = snapshot.value as? [[String:Any]] else {
                completion(false)
                return
            }
            
            let mensajeFecha = nuevoMensaje.sentDate
            let fechaString = ChatViewController.dateFormatter.string(from: mensajeFecha)
            
            var mensaje = ""
            
            switch nuevoMensaje.kind {
            case .text(let mensajeTexto):
                mensaje = mensajeTexto
            case .attributedText(_):
                break
            case .photo( let mediaItem ):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    mensaje = targetUrlString
                }
                break
            case .video( let mediaItem ):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    mensaje = targetUrlString
                }
                break
            case .location( let locationData):
                let location = locationData.location
                mensaje = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
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
            
            let nuevoMensajeEntrada: [String: Any] = [
                "id": nuevoMensaje.messageId,
                "tipo": nuevoMensaje.kind.messagekindString,
                "contenido": mensaje,
                "fecha": fechaString,
                "remitente_email": actualUsuarioEmail,
                "visto": false,
                "nombre": nombre
            ]
            
            actualMensajes.append(nuevoMensajeEntrada)
            
            strongSelf.database.child("\(conversacion)/mensajes").setValue(actualMensajes) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(actualEmail)/conversaciones").observeSingleEvent(of: .value, with: { snapshot in
                    var databaseEntryConversaciones = [[String: Any]]()
                    let actualizadoValor: [String: Any] = [
                        "fecha": fechaString,
                        "mensaje": mensaje,
                        "visto": false
                    ]
                    if var actualUsuarioConversaciones = snapshot.value as? [[String: Any]]  {
                                                
                        var targetConversacion: [String: Any]?
                        
                        var posicion = 0
                        
                        for conversacionDiccionario in actualUsuarioConversaciones {
                            if let actualId = conversacionDiccionario["id"] as? String, actualId == conversacion {
                                targetConversacion = conversacionDiccionario
                                
                                break
                            }
                            posicion += 1
                        }
                        
                        if var targetConversacion = targetConversacion {
                            targetConversacion["ultimo_mensaje"] = actualizadoValor
                            actualUsuarioConversaciones[posicion] = targetConversacion
                            databaseEntryConversaciones = actualUsuarioConversaciones
                        }
                        else {
                            let nuevaConversacionData: [String: Any] = [
                                "id": conversacion,
                                "otro_usuario_email": DatabaseManager.safeEmail(email: otroUsuarioEmail),
                                "nombre": nombre,
                                "ultimo_mensaje":actualizadoValor
                            ]
                            actualUsuarioConversaciones.append(nuevaConversacionData)
                            databaseEntryConversaciones = actualUsuarioConversaciones
                        }
                        
                    }else {
                        let nuevaConversacionData: [String: Any] = [
                            "id": conversacion,
                            "otro_usuario_email": DatabaseManager.safeEmail(email: otroUsuarioEmail),
                            "nombre": nombre,
                            "ultimo_mensaje":actualizadoValor
                        ]
                        databaseEntryConversaciones = [
                            nuevaConversacionData
                        ]
                    }
                    
                    
                    
                    strongSelf.database.child("\(actualEmail)/conversaciones").setValue(databaseEntryConversaciones, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // Actualizar ultimo mensaje para destinatario
                        
                        strongSelf.database.child("\(otroUsuarioEmail)/conversaciones").observeSingleEvent(of: .value, with: { snapshot in
                            let actualizadoValor: [String: Any] = [
                                "fecha": fechaString,
                                "mensaje": mensaje,
                                "visto": false
                            ]
                            var databaseEntryConversaciones = [[String: Any]]()
                            guard let actualNombre = UserDefaults.standard.value(forKey: "nombre") as? String else {
                                return
                            }
                            if var otroUsuarioConversaciones = snapshot.value as? [[String: Any]] {
                                var targetConversacion: [String: Any]?
                                
                                var posicion = 0
                                
                                for conversacionDiccionario in otroUsuarioConversaciones {
                                    if let actualId = conversacionDiccionario["id"] as? String, actualId == conversacion {
                                        targetConversacion = conversacionDiccionario
                                        break
                                    }
                                    posicion += 1
                                }
                                
                                if var targetConversacion = targetConversacion {
                                    targetConversacion["ultimo_mensaje"] = actualizadoValor
                                    
                                    otroUsuarioConversaciones[posicion] = targetConversacion
                                    databaseEntryConversaciones = otroUsuarioConversaciones
                                }
                                else {
                                    let nuevaConversacionData: [String: Any] = [
                                        "id": conversacion,
                                        "otro_usuario_email": DatabaseManager.safeEmail(email: actualEmail),
                                        "nombre": actualNombre,
                                        "ultimo_mensaje":actualizadoValor
                                    ]
                                    otroUsuarioConversaciones.append(nuevaConversacionData)
                                    databaseEntryConversaciones = otroUsuarioConversaciones
                                }
                                
                            }
                            else {
                                let nuevaConversacionData: [String: Any] = [
                                    "id": conversacion,
                                    "otro_usuario_email": DatabaseManager.safeEmail(email: actualEmail),
                                    "nombre": actualNombre,
                                    "ultimo_mensaje":actualizadoValor
                                ]
                                databaseEntryConversaciones = [
                                    nuevaConversacionData
                                ]
                            }
                            
                            
                            strongSelf.database.child("\(otroUsuarioEmail)/conversaciones").setValue(databaseEntryConversaciones, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                    })
                })
            }
        })
    }
    
    public func eliminarConversacion(conversacionId: String, completion: @escaping (Bool) -> Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        
        let ref = database.child("\(safeEmail)/conversaciones")
        ref.observeSingleEvent(of: .value) { snapshot in
            if var conversaciones = snapshot.value as? [[String: Any]]{
                var posicionRemover = 0
                for conversacion in conversaciones{
                    if let id = conversacion["id"] as? String,
                       id == conversacionId{
                        print("Encontro Conversacion eliminada")
                        break
                    }
                    posicionRemover += 1
                }
                
                conversaciones.remove(at: posicionRemover)
                ref.setValue(conversaciones) { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("error al eliminar conversacion")
                        return
                    }
                    print("Conversacion eliminada")
                    completion(true)
                }
            }
        }
    }
    
    public func conversacionExiste(with  targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void){
        let safeRecipientEmail = DatabaseManager.safeEmail(email: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeSenderEmail = DatabaseManager.safeEmail(email: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversaciones").observeSingleEvent(of: .value) { snapshot in
            guard let colleccion = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.falloAlObtener))
                return
            }
            
            if let conversacion = colleccion.first(where: {
                guard let targetsenderEmail = $0["otro_usuario_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetsenderEmail
            }) {
                guard let id = conversacion["id"] as? String else {
                    completion(.failure(DatabaseError.falloAlObtener))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.falloAlObtener))
            return
        }
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
