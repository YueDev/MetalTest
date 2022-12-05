//
// Created by YUE on 2022/11/17.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class MainViewController: UIViewController {

    private let allData = [
        //简单组
        [
            ("基础 01", "TransitionSimple::simple_mix_kernel"),
            ("基础 02", "TransitionSimple::simple_slide_left_kernel"),
            ("基础 03", "TransitionSimple::simple_slide_right_kernel"),
            ("基础 04", "TransitionSimple::simple_slide_up_kernel"),
            ("基础 05", "TransitionSimple::simple_slide_down_kernel"),
            ("基础 06", "TransitionSimple::simple_cover_left_kernel"),
            ("基础 07", "TransitionSimple::simple_cover_right_kernel"),
            ("基础 08", "TransitionSimple::simple_cover_up_kernel"),
            ("基础 09", "TransitionSimple::simple_cover_down_kernel"),
            ("基础 10", "TransitionSimple::simple_heart_out_kernel"),
            ("基础 11", "TransitionSimple::simple_circle_out_kernel"),
            ("基础 12", "TransitionSimple::simple_zoom_out_in_kernel"),
        ],
        [
            ("遮罩 01", "TransitionMark01::mark_01"),
            ("遮罩 02", "TransitionMark02::mark_02"),
            ("遮罩 03", "TransitionMark03::mark_03"),
            ("遮罩 04", "TransitionMark04::mark_04"),
            ("遮罩 05", "TransitionMark05::mark_05"),
            ("遮罩 06", "TransitionMark06::mark_06"),
            ("遮罩 07", "TransitionMark07::mark_07"),
            ("遮罩 08", "TransitionMark08::mark_08"),
        ],
        [
            ("分割 01", "TransitionSplit01::split_01"),
            ("分割 02", "TransitionSplit02::split_02"),
            ("分割 03", "TransitionSplit03::split_03"),
            ("分割 04", "TransitionSplit04::split_04"),
            ("分割 05", "TransitionSplit05::split_05"),
            ("分割 06", "TransitionSplit06::split_06"),
            ("分割 07", "TransitionSplit07::split_07"),
            ("分割 08", "TransitionSplit08::split_08"),
            ("分割 09", "TransitionSplit09::split_09"),
            ("分割 10", "TransitionSplit10::split_10"),
            ("分割 11", "TransitionSplit11::split_11"),
            ("分割 12", "TransitionSplit12::split_12"),
            ("分割 13", "TransitionSplit13::split_13"),
            ("分割 14", "TransitionSplit14::split_14"),
        ],
        [
            ("运镜 01", "TransitionCamera01::camera_01"),
            ("运镜 02", "TransitionCamera02::camera_02"),
            ("运镜 03", "TransitionCamera03::camera_03"),
            ("运镜 04", "TransitionCamera04::camera_04"),
            ("运镜 05", "TransitionCamera05::camera_05"),
        ],
        [
            ("3D 01", "Transition3D01::t3d_01"),
            ("3D 02", "Transition3D02::t3d_02"),
            ("3D 03", "Transition3D03::t3d_03"),
            ("3D 04", "Transition3D04::t3d_04"),
            ("3D 05", "Transition3D05::t3d_05"),
        ]
    ]

    private let headData = [
        "基础",
        "遮罩",
        "分割",
        "运镜",
        "3D",
    ]

    private let disposeBag = DisposeBag()

    private let cellReuseIdentifier = "SwiftCell";

    private lazy var tableView = {
        UITableView.init(frame: .zero, style: .insetGrouped)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = COLOR_APP_BG
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        Observable.just(headData).bind(to: tableView.rx
                .items(cellIdentifier: cellReuseIdentifier, cellType: UITableViewCell.self)) { (row, text, cell) in
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .none
                cell.backgroundColor = COLOR_APP_BG
                cell.textLabel?.text = text
            }
            .disposed(by: disposeBag)

        tableView.rx.itemSelected.bind { [weak self] indexPath in
                guard let data = self?.allData[indexPath.row],
                      let group = self?.headData[indexPath.row]
                else {
                    return
                }
                let vc = ListViewController()
                vc.setData(title: group, data: data)
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

