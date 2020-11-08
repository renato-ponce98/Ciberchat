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
            termino(true)
        })
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
