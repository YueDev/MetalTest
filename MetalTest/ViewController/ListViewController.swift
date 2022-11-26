//
// Created by YUE on 2022/11/17.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class ListViewController: UIViewController {

    private let disposeBag = DisposeBag()

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
        tableView.backgroundColor = COLOR_APP_BG
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        Observable.just(allData).bind(to: tableView.rx.items(
                   cellIdentifier: cellReuseIdentifier,
                   cellType: UITableViewCell.self)
            ) { row, data, cell in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = COLOR_APP_BG
                cell.selectionStyle = .none
                cell.textLabel?.text = data.0
            }
            .disposed(by: disposeBag)

        tableView.rx.itemSelected.bind { [weak self] indexPath in
                guard let data = self?.allData[indexPath.row] else {
                    return
                }
                let vc = KernelViewController()
                vc.setShaderName(data.0, data.1)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)

        view.addSubview(tableView)
    }


    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

