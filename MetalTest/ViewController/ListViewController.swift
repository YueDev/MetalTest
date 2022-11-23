//
// Created by YUE on 2022/11/17.
//

import Foundation
import UIKit

class ListViewController: UIViewController {

    private var allData = [(String, String)]()

    private let cellReuseIdentifier = "SwiftCell";

    private lazy var tableView = {
        UITableView.init(frame: .zero, style: .insetGrouped)
    }()

    func setData(title: String, data: [(String, String)]) {
        allData = data
        self.title = title
    }

    override func viewDidLoad() {
        super.viewDidLoad()


        tableView.backgroundColor = .lightGray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        view.addSubview(tableView)
    }
    

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

extension ListViewController: UITableViewDataSource {



    //每一组的cell数量

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allData.count
    }

    //cell的视图
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        //cell尾部的指示图标
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .lightGray
        cell.selectionStyle = .none

        cell.textLabel?.text = allData[indexPath.row].0
        return cell
    }
}

extension ListViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //选中cell
        let data = allData[indexPath.row]
        let vc = KernelViewController()
        vc.setShaderName(data.0, data.1)
        navigationController?.pushViewController(vc, animated: true)
    }
}

