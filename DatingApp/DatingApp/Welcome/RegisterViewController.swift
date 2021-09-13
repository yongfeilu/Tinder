//
//  RegisterViewController.swift
//  DatingApp
//
//  Created by 卢勇霏 on 5/26/21.
//

import UIKit
import ProgressHUD

class RegisterViewController: UIViewController {

    //MARK:  - IBOutlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var genderSegmentOutlet: UISegmentedControl!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    
    //MARK:  - Vars
    var isMale = true

    
    //MARK:  - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        overrideUserInterfaceStyle = .dark
        setupBackgroundTouch()
        
    }
    

    //MARK:  - IBActions
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func registerButtonPressed(_ sender: Any) {
        
        if isTextDataImputed() {
            // register the user
            if passwordTextField.text! == confirmPasswordTextField.text! {
                registerUser()
            } else {
                ProgressHUD.showError("Passwords don't match!")
            }
            
        } else {
            ProgressHUD.showError("All fields are required!")
        }
    }
    @IBAction func loginButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func genderSegmentValueChanged(_ sender: UISegmentedControl) {
        isMale = sender.selectedSegmentIndex == 0

    }
    
    //MARK:  - Setup
   
    
    private func setupBackgroundTouch() {
        backgroundImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTap))
        backgroundImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc func backgroundTap() {
        dismissKeyboard()
    }
    
    //MARK:  - Helpers
    @objc func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    
 
    
    private func isTextDataImputed() -> Bool {
        return usernameTextField.text != "" && emailTextField.text != "" &&
            cityTextField.text != "" &&
            passwordTextField.text != "" && confirmPasswordTextField.text != ""
    }
    
    //MARK:  - RegisterUser
    private func registerUser() {

        ProgressHUD.show()
        FUser.registerUserWith(email: emailTextField.text!, password: passwordTextField.text!, userName: usernameTextField.text!, city: cityTextField.text!, isMale: isMale, dateOfBirth: datePicker.date) { (error) in
            
            if error == nil {
                ProgressHUD.showSuccess("Verification email sent!")
                self.dismiss(animated: true, completion: nil)
            } else {
                ProgressHUD.showError(error!.localizedDescription)
            }
        }
        
    }
}
