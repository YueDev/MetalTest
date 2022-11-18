//
// Created by YUE on 2022/11/17.
//

import Foundation
import UIKit

class MainViewController: UIViewController {

    private let allData = [
        //简单组
        [
            ("渐变", "simple_vertex", "simple_fragment_mix"),
            ("向左滑动", "simple_vertex", "simple_fragment_slide_left"),
            ("向右滑动", "simple_vertex", "simple_fragment_slide_right"),
            ("向上滑动", "simple_vertex", "simple_fragment_slide_up"),
            ("向下滑动", "simple_vertex", "simple_fragment_slide_down"),
            ("向左覆盖", "simple_vertex", "simple_fragment_cover_left"),
            ("向右覆盖", "simple_vertex", "simple_fragment_cover_right"),
            ("向上覆盖", "simple_vertex", "simple_fragment_cover_up"),
            ("向下覆盖", "simple_vertex", "simple_fragment_cover_down"),
            ("心形", "simple_vertex", "simple_fragment_heart_out"),
        ],
    ]

    private let headData = [
        "基础",
    ]

    private let cellReuseIdentifier = "SwiftCell";

    private lazy var tableView = {
        UITableView.init(frame: .zero, style: .grouped)
    }()

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

extension MainViewController: UITableViewDataSource {

    //分组数量
    public func numberOfSections(in tableView: UITableView) -> Int {
        headData.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        headData[section]
    }


    //每一组的cell数量

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allData[section].count
    }

    //cell的视图

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        //cell尾部的指示图标
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .lightGray
        cell.selectionStyle = .none

        cell.textLabel?.text = allData[indexPath.section][indexPath.row].0
        return cell
    }
}

extension MainViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //选中cell
        let vertex = allData[indexPath.section][indexPath.row].1
        let fragment = allData[indexPath.section][indexPath.row].2
        let vc = MetalViewController()
        vc.setShaderName(vertex, fragment)
        navigationController?.pushViewController(vc, animated: true)
    }
}
