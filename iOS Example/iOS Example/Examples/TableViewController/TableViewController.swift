//
//  TableViewController.swift
//  iOS Example
//
//  Created by Amr Mohamed on 11/02/2023.
//

import UIKit

class TableViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        title = "TableViewController"
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset.top = 10
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
}

extension TableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        9
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = "Hello Cell \(indexPath.section) \(indexPath.row)"
        return cell
    }
}
