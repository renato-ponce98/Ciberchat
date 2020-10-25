//
//  AppDelegate.swift
//  Ciberchat
//
//  Created by user182813 on 10/17/20.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        return true
        
    }
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Ocurrio un error al iniciar sesion con Google: \(error)")
            }
            return
        }
        
        guard let user = user else {
            return
        }
        
        print("Inicio sesion con : \(user)")
        
        guard let email = user.profile.email,
              let nombre = user.profile.givenName,
              let apellido = user.profile.familyName else {
            return
        }
        
        DatabaseManager.shared.usuarioExiste(with: email, completion: { exists in
            if !exists {
                DatabaseManager.shared.insertarUsuario(with: CiberchatUsuario(nombres: nombre,
                                                                              apellidos: apellido,
                                                                              email: email))
            }
        })
        
        guard let authentication = user.authentication else {
            print("Falta la autenticacion del usuario de google")
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        FirebaseAuth.Auth.auth().signIn(with: credential, completion: {authResult, error in
            guard authResult != nil, error == nil else {
                print("Fallo al iniciar sesion con google")
                return
            }
            
            print("Inicio de sesion exitoso con google")
            NotificationCenter.default.post(name: .LogInNotificacion, object: nil)
        })
    }
     
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Usuario google ha cerrado sesion")
    }
}

