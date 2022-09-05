//
//  ViewController.swift
//  MobileStorage
//
//  Created by Анатолий Силиверстов on 04.09.2022.
//

import UIKit
import RealmSwift

protocol MobileStorage {
    func getAll() -> Set<Mobile>
    func findByImei(_ imei: String) -> Mobile?
    func save(_ mobile: Mobile) throws -> Mobile
    func delete(_ product: Mobile) throws
    func exists(_ product: Mobile) -> Bool
}

class ViewController: UIViewController, MobileStorage {
    
    let localRealm = try! Realm()
    
    private var mobiles: [Mobile] = []
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var foundedMobiles = [Mobile]()
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else {return false}
        return text.isEmpty
    }
    private var isSearching: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mobiles"
        mobiles.append(contentsOf: getAll())
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        setupSearchController()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addMobile))
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by IMEI"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    @objc private func addMobile() {
        let alert = UIAlertController(title: "Add new mobile",
                                      message: "",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter mobile model"
        }
        alert.addTextField { textField in
            textField.placeholder = "Enter mobile EMEI"
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            guard let modelTextField = alert.textFields?.first, let modelText = modelTextField.text, !modelText.isEmpty
            else {return}
            guard let imeiTextField = alert.textFields?.last, let imeiText = imeiTextField.text, !imeiText.isEmpty
            else {return}
            
            let warningAlert = UIAlertController(title: "Warning", message: "This model already exists", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel)
            warningAlert.addAction(okAction)
            
            let newMobile = Mobile(imei: imeiText, model: modelText)
            
            let exists = self.exists(newMobile)
            if exists {
                self.present(warningAlert, animated: true)
            } else {
                
                let savedMobile = try! self.save(newMobile)
                
                self.mobiles.append(savedMobile)
                let indexPath = IndexPath(row: self.mobiles.count - 1, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    //MARK: - Mobile Storage Protocol
    func getAll() -> Set<Mobile> {
        let mobiles = localRealm.objects(Mobile.self)
        return Set(mobiles.compactMap {$0})
    }
    
    func findByImei(_ imei: String) -> Mobile? {
        let foundedMobile = mobiles.filter({ mobile in
            return mobile.imei.contains(imei)
        }).first
        return foundedMobile
    }
    
    func save(_ mobile: Mobile) throws -> Mobile {
        try! localRealm.write {
            localRealm.add(mobile)
        }
        return mobile
    }
    
    func delete(_ product: Mobile) {
        try! localRealm.write {
            localRealm.delete(product)
        }
    }
    
    func exists(_ product: Mobile) -> Bool {
        let mobiles = getAll()
        
        return mobiles.contains(where: { $0.imei == product.imei })
    }
}

//MARK: - TableView Delegate, DataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return foundedMobiles.count
        }
        return mobiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var mobile: Mobile
        if isSearching {
            mobile = foundedMobiles[indexPath.row]
        } else {
            mobile = mobiles[indexPath.row]
        }
        var content = cell.defaultContentConfiguration()
        content.text = "Model: \(mobile.model)"
        content.secondaryText = "IMEI: \(mobile.imei)"
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            self.delete(self.mobiles[indexPath.row])
            self.mobiles.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
        
        let swipeActions = UISwipeActionsConfiguration(actions: [deleteAction])
        return swipeActions
    }
}

//MARK: - SearchResultsUpdating
extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        if let foundedMobile = findByImei(searchText) {
            foundedMobiles = [foundedMobile]
        } else {
            foundedMobiles = []
        }
        self.tableView.reloadData()
    }
}

