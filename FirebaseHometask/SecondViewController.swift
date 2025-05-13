//
//  SecondViewController.swift
//  FirebaseTest
//
//  Created by Rəşad Əliyev on 5/8/25.
//

import UIKit
import FirebaseAuth
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import SDWebImage

class SecondViewController: UIViewController {
    
    private var imageUrls: [URL] = []
    
    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Sign out", for: .normal)
        button.backgroundColor = .systemBlue
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.itemSize = CGSize(width: 88, height: 88)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        
        setupUI()
        setupNavBar()
        setupButton()
        fetchImagesFromFirebase()
    }
    
    private func fetchImagesFromFirebase() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("images").order(by: "timestamp", descending: true).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            self.imageUrls = documents.compactMap {
                URL(string: $0.data()["url"] as? String ?? "")
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    private func setupNavBar() {
        let rightBarButton = UIBarButtonItem(image: .add, style: .done, target: self, action: #selector(didTapAdd))
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    @objc private func didTapAdd() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func setupButton() {
        signOutButton.addTarget(self, action: #selector(didTapSignOut), for: .touchUpInside)
    }
    
    @objc private func didTapSignOut() {
        
        do {
            try FirebaseAuth.Auth.auth().signOut()
            let vc = ViewController()
            navigationController?.setViewControllers([vc], animated: true)
        } catch {
            print("Couldn't sign out")
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemRed
        view.addSubview(signOutButton)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            signOutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            signOutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            signOutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: signOutButton.topAnchor, constant: 8),
        ])
    }
    
    func saveImageURLToFirestore(url: URL) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("images").addDocument(data: [
            "url": url.absoluteString,
            "timestamp": Timestamp()
        ]) { error in
            if error == nil {
                self.imageUrls.append(url)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func uploadToFirebase(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let uid = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("users/\(uid)/\(UUID().uuidString).jpg")
        storageRef.putData(imageData) { metadata, error in
            if let error {
                print(error)
                return
            }
            
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else { return }
                self.saveImageURLToFirestore(url: downloadURL)
            }
        }
    }
}


extension SecondViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCell else { return UICollectionViewCell() }
        
        let url = imageUrls[indexPath.row]
        cell.imageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "photo")) { image, error, _, url in
            if let error {
                print("Failed to load image from \(url?.absoluteString ?? "unknown")", error.localizedDescription)
            }
        }
        return cell
    }
}

extension SecondViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
        itemProvider.loadObject(ofClass: UIImage.self) {[weak self]
            image, error in
            guard let image = image as? UIImage else { return }
            DispatchQueue.main.async {
                self?.uploadToFirebase(image)
            }
        }
    }
}
