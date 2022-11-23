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
            ("遮罩01", "TransitionMark01::mark_01"),
            ("遮罩02", "TransitionMark02::mark_02"),
            ("遮罩03", "TransitionMark03::mark_03"),
            ("遮罩04", "TransitionMark04::mark_04"),
            ("遮罩05", "TransitionMark05::mark_05"),
            ("遮罩06", "TransitionMark06::mark_06"),
            ("遮罩07", "TransitionMark07::mark_07"),
            ("遮罩08", "TransitionMark08::mark_08"),
        ],
        [
            ("分割01", "TransitionSplit01::split_01"),
            ("分割02", "TransitionSplit02::split_02"),
            ("分割03", "TransitionSplit03::split_03"),
            ("分割04", "TransitionSplit04::split_04"),
            ("分割05", "TransitionSplit05::split_05"),
            ("分割06", "TransitionSplit06::split_06"),
            ("分割07", "TransitionSplit07::split_07"),
            ("分割08", "TransitionSplit08::split_08"),
            ("分割09", "TransitionSplit09::split_09"),
            ("分割10", "TransitionSplit10::split_10"),
            ("分割11", "TransitionSplit11::split_11"),
            ("分割12", "TransitionSplit12::split_12"),
            ("分割13", "TransitionSplit13::split_13"),
            ("分割14", "TransitionSplit14::split_14"),
        ],
        [
            ("运镜01", "TransitionCamera01::camera_01"),
            ("运镜02", "TransitionCamera02::camera_02"),
            ("运镜03", "TransitionCamera03::camera_03"),
            ("运镜04", "TransitionCamera04::camera_04"),
            ("运镜05", "TransitionCamera05::camera_05"),
        ]
    ]

    private let headData = [
        "基础",
        "遮罩",
        "分割"
    ]

    private let cellReuseIdentifier = "SwiftCell";

    private lazy var tableView = {
        UITableView.init(frame: .zero, style: .insetGrouped)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.init
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
