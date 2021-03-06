//
//  AccountManagerViewController.swift
//  V2ex-Swift
//
//  Created by huangfeng on 2/11/16.
//  Copyright © 2016 Fin. All rights reserved.
//

import UIKit

/// 多账户管理
class AccountsManagerViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate {
    fileprivate var users:[LocalSecurityAccountModel] = []
    fileprivate var _tableView :UITableView!
    fileprivate var tableView: UITableView {
        get{
            if(_tableView != nil){
                return _tableView!;
            }
            _tableView = UITableView();
            _tableView.backgroundColor = V2EXColor.colors.v2_backgroundColor
            _tableView.estimatedRowHeight=100;
            _tableView.separatorStyle = UITableViewCellSeparatorStyle.none;

            regClass(_tableView, cell: BaseDetailTableViewCell.self);
            regClass(_tableView, cell: AccountListTableViewCell.self);
            regClass(_tableView, cell: LogoutTableViewCell.self)

            _tableView.delegate = self;
            _tableView.dataSource = self;
            return _tableView!;

        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("accounts")
        self.view.backgroundColor = V2EXColor.colors.v2_backgroundColor

        let warningButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        warningButton.contentMode = .center
        warningButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -20)
        warningButton.setImage(UIImage.imageUsedTemplateMode("ic_warning")!.withRenderingMode(.alwaysTemplate), for: UIControlState())
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: warningButton)
        warningButton.addTarget(self, action: #selector(AccountsManagerViewController.warningClick), for: .touchUpInside)

        self.view.addSubview(self.tableView);
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
        self.tableView.snp.makeConstraints{ (make) -> Void in
            make.top.bottom.equalTo(self.view);
            make.center.equalTo(self.view);
            make.width.equalTo(SCREEN_WIDTH)
        }

        for (_,user) in V2UsersKeychain.sharedInstance.users {
            self.users.append(user)
        }

    }

    func warningClick(){
        let alertView = UIAlertView(title: "临时隐私声明", message: "当你登录时，软件会自动将你的账号与密码保存于系统的Keychain中（非常安全）。如果你不希望软件保存你的账号与密码，可以左滑账号并点击删除。\n后续会完善隐私声明页面，并添加 关闭保存账号密码机制 的选项。\n但我强烈推荐你不要关闭，因为这个会帮助你【登录过期自动重连】、或者【切换多账号】", delegate: nil, cancelButtonTitle: "我知道了")
        alertView.show()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //     账户数量            分割线   退出登录按钮
        return self.users.count   + 1       + 1
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < self.users.count {
            return 55
        }
        else if indexPath.row == self.users.count {//分割线
            return 15
        }
        else { //退出登录按钮
            return 45
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < self.users.count {
            let cell = getCell(tableView, cell: AccountListTableViewCell.self, indexPath: indexPath)
            cell.bind(self.users[indexPath.row])
            return cell
        }
        else if indexPath.row == self.users.count {//分割线
            let cell = getCell(tableView, cell: BaseDetailTableViewCell.self, indexPath: indexPath)
            cell.detailMarkHidden = true
            cell.backgroundColor = tableView.backgroundColor
            return cell
        }
        else{
            return getCell(tableView, cell: LogoutTableViewCell.self, indexPath: indexPath)
        }
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        if indexPath.row < self.users.count{
            return true
        }
        return false
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let username = self.users[indexPath.row].username {
                self.users.remove(at: indexPath.row)
                V2UsersKeychain.sharedInstance.removeUser(username)
                tableView.deleteRows(at: [indexPath], with: .none)
            }
        }
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)

        let totalNumOfRows = self.tableView(tableView, numberOfRowsInSection: 0)
        if indexPath.row < self.users.count {
            let user = self.users[indexPath.row]
            if user.username == V2User.sharedInstance.username {
                return;
            }
            let alertView = UIAlertView(title: "确定切换到账号 " + user.username! + " 吗?", message: "无论新账号是否登录成功，都会注销当前账号。", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定")
            //这里一个属性两用了，除了用于标记它是切换账号的 alertView, 后面还加上了当前是点击了第几个账号
            //太懒了，懒得用其他什么写法
            //同学们注意，这种写法是相当的low的，如果硬要这样写，千万要留下足够的注释解释
            alertView.tag = 100001 + indexPath.row
            alertView.show()
        }
        else if indexPath.row == totalNumOfRows - 1{ //最后一行，也就是退出登录按钮那行
            let alertView = UIAlertView(title: "确定注销当前账号吗？", message: "注销只会退出登录，并不会删除保存在Keychain中的账户名与密码。如需删除，请左滑需要删除的账号，然后点击删除按钮", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "注销")
            alertView.tag = 100000
            alertView.show()
        }
    }
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int){
        if alertView.tag > 100000 { //切换账号的alertView
            if buttonIndex == 0 {
                return
            }
            V2User.sharedInstance.loginOut()
            self.tableView.reloadData()

            let user = self.users[alertView.tag - 100001]

            if let username = user.username,let password = user.password {
                V2BeginLoadingWithStatus("正在登录")
                UserModel.Login(username, password: password){
                    (response:V2ValueResponse<String> , is2FALoggedIn:Bool) -> Void in
                    if response.success {
                        V2Success("登录成功")
                        let username = response.value!
                        NSLog("登录成功 %@",username)
                        //保存下用户名
                        V2EXSettings.sharedInstance[kUserName] = username
                        //获取用户信息
                        UserModel.getUserInfoByUsername(username, completionHandler: { (response) -> Void in
                            self.tableView.reloadData()
                        })
                        if is2FALoggedIn {
                            let twoFaViewController = TwoFAViewController()
                            V2Client.sharedInstance.centerViewController!.navigationController?.present(twoFaViewController, animated: true, completion: nil);
                        }
                    }
                    else{
                        V2Error(response.message)
                    }
                }
            }
        }
        else { //注销登录的alertView
            if buttonIndex == 1 {
                V2User.sharedInstance.loginOut()
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}
