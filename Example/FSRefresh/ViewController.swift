//
//  ViewController.swift
//  FSRefresh
//
//  Created by lifusheng on 10/21/2017.
//  Copyright (c) 2017 lifusheng. All rights reserved.
//

import UIKit
import FSRefresh

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    deinit {
        print("deinit")
    }
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
//        table.contentInset = UIEdgeInsetsMake(64, 0, 0, 0)
        table.backgroundColor = .white
        table.tableFooterView = UIView()
        table.scrollIndicatorInsets = table.contentInset
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cellId")
        
        table.layer.borderWidth = 2.0
        table.layer.borderColor = UIColor.red.cgColor
        
        table.clipsToBounds = false
        
        table.fs_addHeaderRefresh({ [weak self] in
            
            print("begin header refresh !")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                self?.tableView.fs_stopHeaderRefresh(success: true)
            })
        })
        
        table.fs_addFooterRefresh({ [weak self] in
            
            guard let `self` = self else {
                return
            }
            
            print("begin footer refresh !")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                self.tableView.fs_stopFooterRefresh(isNoMoreData: true)
            })
        })
        
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .yellow
        
//        self.automaticallyAdjustsScrollViewInsets = false
//        if #available(iOS 11.0, *) {
//            tableView.contentInsetAdjustmentBehavior = .never
//        }
        
//        tableView.contentOffset.y = -tableView.contentInset.top
        
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
//        if #available(iOS 11.0, *) {
//            view.addConstraint(NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1.0, constant: 0.0))
//        } else {
//            view.addConstraint(NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: self.topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0))
//        }
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[tableView]|", options: [], metrics: nil, views: ["tableView" : tableView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: ["tableView" : tableView]))
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
//            self.tableView.contentInset.top = 50
//        })
        
        view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("[\(tableView.contentInset)]\n")
        if #available(iOS 11.0, *) {
            print("[\(tableView.adjustedContentInset)]\n")
        }
        
//        tableView.fs_startHeaderRefresh()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId")
        cell?.textLabel?.text = "第 \(indexPath.row + 1) 行"
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = ViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

