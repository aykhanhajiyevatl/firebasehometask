//
//  ViewController.swift
//  FirebaseHometask
//
//  Created by Rəşad Əliyev on 5/11/25.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {
    
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Write your email..."
        textField.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Write your password..."
//        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("register", for: .normal)
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.backgroundColor = .systemRed
        return button
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("login", for: .normal)
        button.backgroundColor = .systemBlue
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupButton()
    }
    
    private func setupButton() {
        loginButton.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
        
        registerButton.addTarget(self, action: #selector(didTapRegisterButton), for: .touchUpInside)
    }
    
    @objc private func didTapRegisterButton() {
        FirebaseAuth.Auth.auth().createUser(withEmail: emailTextField.text ?? "", password: passwordTextField.text ?? "") {[weak self]
            result, error in
            if let error {
                let alert = UIAlertController(title: "Oops!", message: "\(error.localizedDescription)", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "Go back", style: .cancel)
                alert.addAction(cancel)
                self?.present(alert, animated: true)
                return
            }
            
            print(result ?? "")
            
            let alert = UIAlertController(title: "Successful!", message: "You have registered new account", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Great!", style: .cancel)
            alert.addAction(cancel)
            self?.present(alert, animated: true)
        }
    }
    
    @objc private func didTapLoginButton() {
        FirebaseAuth.Auth.auth().signIn(withEmail: emailTextField.text ?? "", password: passwordTextField.text ?? "") {[weak self]
            result, error in
            if let error {
                print("Something went wrong... \(error)")
                return
            }
            
            print("Success")
            let vc = SecondViewController()
            self?.navigationController?.setViewControllers([vc], animated: true)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        
        [mainStackView, registerButton, loginButton].forEach { component in
            view.addSubview(component)
        }
        
        [emailTextField, passwordTextField].forEach { component in
            mainStackView.addArrangedSubview(component)
        }
        
        NSLayoutConstraint.activate([
            mainStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            registerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            loginButton.bottomAnchor.constraint(equalTo: registerButton.topAnchor, constant: -8),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }


}

