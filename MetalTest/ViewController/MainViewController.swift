//
// Created by YUE on 2022/11/17.
//

import Foundation
import UIKit

class MainViewController: UIViewController {

    private let allData = [
        //简单组
        [
            ("渐变", "TransitionSimple::simple_mix_kernel"),
            ("向左滑动", "TransitionSimple::simple_slide_left_kernel"),
            ("向右滑动", "TransitionSimple::simple_slide_right_kernel"),
            ("向上滑动", "TransitionSimple::simple_slide_up_kernel"),
            ("向下滑动", "TransitionSimple::simple_slide_down_kernel"),
            ("向左覆盖", "TransitionSimple::simple_cover_left_kernel"),
            ("向右覆盖", "TransitionSimple::simple_cover_right_kernel"),
            ("向上覆盖", "TransitionSimple::simple_cover_up_kernel"),
            ("向下覆盖", "TransitionSimple::simple_cover_down_kernel"),
            ("心形", "TransitionSimple::simple_heart_out_kernel"),
            ("圆形", "TransitionSimple::simple_circle_out_kernel"),
            ("放大缩小", "TransitionSimple::simple_zoom_out_in_kernel"),
        ],
        [
            ("遮罩1", "TransitionMark01::mark_01"),
            ("遮罩2", "TransitionMark02::mark_02"),
            ("遮罩3", "TransitionMark03::mark_03"),
            ("遮罩4", "TransitionMark04::mark_04"),
            ("遮罩5", "TransitionMark05::mark_05"),
            ("遮罩6", "TransitionMark06::mark_06"),
            ("遮罩7", "TransitionMark07::mark_07"),
            ("遮罩8", "TransitionMark08::mark_08"),
        ],
    ]

    private let headData = [
        "基础",
        "遮罩",
    ]

    private let cellReuseIdentifier = "SwiftCell";

    private lazy var tableView = {
        UITableView.init(frame: .zero, style: .insetGrouped)
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


    //分组 需要分组打开
//    public func numberOfSections(in tableView: UITableView) -> Int {
//        1
//    }
//
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        headData[section]
//    }


    //每一组的cell数量

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        headData.count
    }

    //cell的视图
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        //cell尾部的指示图标
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .lightGray
        cell.selectionStyle = .none

        cell.textLabel?.text = headData[indexPath.row]
        return cell
    }
}

extension MainViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //选中cell
        let data = allData[indexPath.row]
        let group = headData[indexPath.row]

        let vc = ListViewController()
        vc.setData(title: group, data: data)
        navigationController?.pushViewController(vc, animated: true)
    }
}
