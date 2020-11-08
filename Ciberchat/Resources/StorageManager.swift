//
//  StorageManager.swift
//  Ciberchat
//
//  Created by user182813 on 11/8/20.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias subirTerminoImagen = (Result<String, Error>) -> Void
    
    //Subir imagen a firebase y retorna url paara descargar
    public func subirImagenPerfil(with data: Data, nombreArchivo: String, termino: @escaping subirTerminoImagen){
        storage.child("images/\(nombreArchivo)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else{
                print("Fallo al subir imagen a firebase")
                termino(.failure(StorageErrors.falloAlSubir))
                return
            }
            
            self.storage.child("images/\(nombreArchivo)").downloadURL(completion: {url, error in
                guard let url = url else {
                    print("Fallo al obtener url de descarga")
                    termino(.failure(StorageErrors.falloAlObtenerUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("Url de descarga: \(urlString)")
                termino(.success(urlString))
            })
        })
    }
    
    public enum StorageErrors: Error {
        case falloAlSubir
        case falloAlObtenerUrl
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void){
        let referencia = self.storage.child(path)
        print(path)
        
        referencia.downloadURL(completion: {url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.falloAlObtenerUrl))
                return
            }
            
            completion(.success(url))
        })
    }
}
