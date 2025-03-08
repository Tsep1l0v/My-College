//
//  Onboording.swift
//  test111
//
//  Created by Дмитрий Цепилов on 08.12.2024.
//

import UIKit

class OnboardingViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var pages = [UIViewController]()
    let pageControl = UIPageControl()
    var completionHandler: (() -> Void)?

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self

        let page1 = AnimationViewController()

        pages.append(page1)

        setViewControllers([pages[0]], direction: .forward, animated: true, completion: nil)

        configurePageControl()

        // Добавьте кнопку для завершения онбординга
        let finishButton = UIButton(type: .system)
        finishButton.setTitle("Закрыть", for: .normal)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.backgroundColor = UIColor(hex: "#0d80ff")
        finishButton.layer.cornerRadius = 10
        finishButton.layer.masksToBounds = true
        finishButton.addTarget(self, action: #selector(finishOnboarding), for: .touchUpInside)
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(finishButton)

        NSLayoutConstraint.activate([
            finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            finishButton.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),
            finishButton.widthAnchor.constraint(equalToConstant: 200),
            finishButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        completionHandler?()
    }

    func configurePageControl() {
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        pageControl.tintColor = .black
        pageControl.pageIndicatorTintColor = .gray
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(pageControl)

        NSLayoutConstraint.activate([
            pageControl.widthAnchor.constraint(equalTo: view.widthAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: 20),
            pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let previousIndex = index - 1
        guard previousIndex >= 0 else { return nil }
        return pages[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let nextIndex = index + 1
        guard nextIndex < pages.count else { return nil }
        return pages[nextIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let currentViewController = pageViewController.viewControllers?.first,
           let index = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = index
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let firstViewController = pendingViewControllers.first else { return }
        guard let index = pages.firstIndex(of: firstViewController) else { return }
        pageControl.currentPage = index
    }
}

// Расширение для UIColor, чтобы использовать hex-код
extension UIColor {
    convenience init(hex: String) {
        var hexFormatted = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }

        assert(hexFormatted.count == 6, "Invalid hex code used.")

        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}




