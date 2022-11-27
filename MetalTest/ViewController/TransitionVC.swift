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
    private let bgColorStart = UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
    private let bgColorEnd = UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)

    private let contentView = UIView()

    override func viewDidLoad() {
        view.backgroundColor = bgColorStart
        contentView.backgroundColor = .black
        view.addSubview(contentView)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        contentView.snp.makeConstraints {make in

        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("YUEDEVTAG viewWillAppear")
    }

    private func finish() {
        UIView.animate(withDuration: 0.3) { [self] in
            view.backgroundColor = bgColorStart
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }

}


