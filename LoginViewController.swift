

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet var loginButton: UIButton!
    @IBOutlet var singinButton: UIButton!
    @IBOutlet var email: UITextField!
    @IBOutlet var password: UITextField!
    
    let remoteConfig = RemoteConfig.remoteConfig()
    var color : String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        try! Auth.auth().signOut()
        
        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { (m) in
            m.right.top.left.equalTo(self.view)
            m.height.equalTo(20)
            
        }
        
        color = remoteConfig["splash_background"].stringValue
        
        statusBar.backgroundColor = UIColor(hex: color)
        loginButton.backgroundColor = UIColor(hex: color)
        singinButton.backgroundColor = UIColor(hex: color)
        
        loginButton.addTarget(self, action: #selector(loginEvent), for: .touchUpInside)
        singinButton.addTarget(self, action: #selector(presentSignup), for: .touchUpInside)

        Auth.auth().addStateDidChangeListener {
            (auth, user) in
            if (user != nil) {
                let view = self.storyboard?.instantiateViewController(withIdentifier: "MainViewTabBarController") as! UITabBarController
                self.present(view, animated: true)
            }
        }
    }
    
    func loginClick() {
        //self.view.makeToast("로그인 버튼 클릭했음", duration: 3.0, position: .top)
        self.view.makeToast("토스트 테스트 x:200 y300", duration: 3.0, point: CGPoint(x: 200.0, y: 300.0), title: "Toast Title", image: UIImage(named: "loading_icon.png")) { didTap in
            if didTap {
                print("completion from tap")
            } else {
                print("completion without tap")
            }
        }

    }
    
    func loginEvent() {
        
        Auth.auth().signIn(withEmail: email.text!, password: password.text!) { (user, err) in
            
            if (err != nil) {
                let alert = UIAlertController(title: "에러", message: err.debugDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    func presentSignup() {
        let view = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        self.present(view, animated: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

   
}
