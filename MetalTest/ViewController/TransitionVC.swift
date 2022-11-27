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

    private let disposeBag = DisposeBag()

    private let contentView = UIView()
    private let button = UIButton.init(type: .roundedRect)

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

    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

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


