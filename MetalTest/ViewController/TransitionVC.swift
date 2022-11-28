//
//  TransitionVC.swift
//  fotoplay
//
//  Created by YUE on 2022/11/26.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class TransitionVC: UIViewController {

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

    private let disposeBag = DisposeBag()

    private let contentView = UIView()
    private let button = UIButton.init(type: .roundedRect)

    private lazy var collectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(width: 70, height: 50)
        layout.sectionInset = .init(top: 8, left: 8, bottom: 8, right: 8)

        return UICollectionView.init(frame: .zero, collectionViewLayout: layout)
    }()


    private let reuesId = "transition_reuse_id"

    override func viewDidLoad() {
        view.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.0)
        contentView.backgroundColor = .black
        view.addSubview(contentView)

        button.sizeToFit()
        button.setTitle("OK", for: .normal)
        button.rx.tap.bind {
                self.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        contentView.addSubview(button)

        collectionView.backgroundColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        collectionView.register(TransitionCell.self, forCellWithReuseIdentifier: reuesId)

        contentView.addSubview(collectionView)

        //这个flatmap的$0是个数组，并不是真正的item，因此需要再map一下
        var initData = allData.flatMap {
                $0
            }
            .map {
                CellState(name: $0.0, isSelect: false)
            }

        initData.insert(CellState(name: "无", isSelect: true), at: 0)

        let initVm = CollectionViewModel(items: initData)

        let selectCommand = collectionView.rx.itemSelected.asObservable()
            .map(Command.select)

        Observable.of(selectCommand)
            .merge()
            .scan(initVm) { (vm, command) -> CollectionViewModel in
                vm.execute(command)
            }
            .startWith(initVm)
            .map(\.items)
            .bind(to: collectionView.rx.items(cellIdentifier: reuesId, cellType: TransitionCell.self)) { i, item, cell in
                cell.setState(state: item)
            }
            .disposed(by: disposeBag)


    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        collectionView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(button.snp.bottom).offset(8)
        }

        button.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(8)
        }

        contentView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(view.center)
        }
    }

}

typealias CellState = (name: String, isSelect: Bool)


fileprivate class TransitionCell: UICollectionViewCell {
    private let label = UILabel()
    private let selectView = UIView()

    private var cellState = CellState("无", false)

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        contentView.addSubview(label)

        selectView.backgroundColor = .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1)
        contentView.addSubview(selectView)
    }

    override func layoutSubviews() {
        label.frame = contentView.frame
        selectView.frame = contentView.frame
    }

    func setState(state: CellState) {
        selectView.isHidden = !state.isSelect
        label.text = state.name
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder: NSCoder) has not been implemented")
    }
}

//表格的选中在这里

fileprivate struct CollectionViewModel {

    let items: [CellState]

    func execute(_ command: Command) -> CollectionViewModel {
        switch command {
        case .select(let indexPath):
            print("select")
            var items = self.items
            if let oldIndex = items.firstIndex(where: \.isSelect) {
                items[oldIndex].isSelect = false
            }
            items[indexPath.row].isSelect = true
            return CollectionViewModel(items: items)
        }
    }
}

fileprivate enum Command {
    case select(indexPath: IndexPath)
}