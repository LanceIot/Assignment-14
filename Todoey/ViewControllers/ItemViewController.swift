//
//  ViewController.swift
//  Todoey
//
//  Created by Админ on 07.03.2023.
//

import UIKit
import SnapKit

final class ItemViewController: UIViewController {
    
    private var selectedSection: Int
    
    init(selectedSection: Int) {
        self.selectedSection = selectedSection
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private var models = [Todoeyitem]()
    
    private lazy var searchBar: UISearchBar = {
       let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()
    
    private lazy var itemTableView: UITableView = {
       let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.register(TodoeyTableViewCell.self, forCellReuseIdentifier: TodoeyTableViewCell.IDENTIFIER)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        
        ItemManager.shared.delegate = self
        ItemManager.shared.fetchItems(self.selectedSection)
        
        itemTableView.dataSource = self
        itemTableView.delegate = self
        searchBar.delegate = self
        
        configureNavBar()
        setupViews()
        setupConstraints()
    }
}

//MARK: - Private controller methods
private extension ItemViewController {
    func configureNavBar() {
        navigationItem.title = "Todoey"
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))
        navigationItem.rightBarButtonItem = add
        navigationController?.navigationBar.tintColor = .label
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    @objc func addButtonPressed() {
        let alert = UIAlertController(title: "New Item", message: "Create new item", preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "Submit", style: .cancel, handler: { _ in
            guard let field = alert.textFields?.first, let text = field.text, !text.isEmpty else {return}
            ItemManager.shared.createItem(with: text, self.selectedSection)
        }))
        
        present(alert, animated: true)
    }
}

//MARK: - Data manager delegate methods
extension ItemViewController: ItemManagerDelegate {
    func didUpdateItems(with models: [Todoeyitem]) {
        self.models = models
        DispatchQueue.main.async {
            self.itemTableView.reloadData()
        }
    }
    
    func didFailWith(with error: Error) {
        print("Following error appeared: ", error)
    }
}

//MARK: - Table view data source methods
extension ItemViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TodoeyTableViewCell.IDENTIFIER, for: indexPath) as! TodoeyTableViewCell
        cell.selectionStyle = .none
        cell.configure(name: models[indexPath.row].name!)
        return cell
    }
}

//MARK: - Table view delegate methods
extension ItemViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.size.height * 0.1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sheet = UIAlertController(title: "Edit", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in
            
            let alert = UIAlertController(title: "Update Item", message: "Update your item", preferredStyle: .alert)
            alert.addTextField()
            alert.textFields?.first?.text = self.models[indexPath.row].name
            alert.addAction(UIAlertAction(title: "Submit", style: .cancel, handler: { _ in
                guard let field = alert.textFields?.first, let text = field.text, !text.isEmpty else {return}
                ItemManager.shared.updateItem(item: self.models[indexPath.row], newName: text, self.selectedSection)
            }))
            
            self.present(alert, animated: true)
        }))
        sheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            ItemManager.shared.deleteItem(item: self.models[indexPath.row], self.selectedSection)
        }))
        
        present(sheet, animated: true)
    }
}

//MARK: - Search bar delegate methods
extension ItemViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        ItemManager.shared.fetchItems(with: searchText, self.selectedSection)
    }
}

//MARK: - Setup view and contraints methods
private extension ItemViewController {
    
    func setupViews() {
        view.addSubview(searchBar)
        view.addSubview(itemTableView)
    }
    
    func setupConstraints() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        searchBar.searchTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(7)
        }
        itemTableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
}

