# RxOperators
[![CI Status](https://img.shields.io/travis/Voidilov/RxOperators.svg?style=flat)](https://travis-ci.org/Voidilov/RxOperators)
[![Version](https://img.shields.io/cocoapods/v/RxOperators.svg?style=flat)](https://cocoapods.org/pods/RxOperators)
[![License](https://img.shields.io/cocoapods/l/RxOperators.svg?style=flat)](https://cocoapods.org/pods/RxOperators)
[![Platform](https://img.shields.io/cocoapods/p/RxOperators.svg?style=flat)](https://cocoapods.org/pods/RxOperators)

## Description

This repo includes operators for RxSwift and some additional features.

Example

 ```swift
 import UIKit
 import RxSwift
 import RxCocoa
 import RxOperators

final class SomeViewModel {
	let title = ValueSubject("Title")
	let icon = ValueSubject<UIImage?>(nil)
	let color = ValueSubject(UIColor.white)
	let bool = ValueSubject(false)
	...
} 

class ViewController: UIViewController {

	@IBOutlet private weak var titleLabel: UILabel!
	@IBOutlet private weak var iconView: UIImageView!
	@IBOutlet private weak var switchView: UISwitch!

	let viewModel = SomeViewModel()
	...
	private func configureSubscriptions() {
		viewModel.title ==> titleLabel.rx.text
		viewModel.iconView ==> iconView.rx.image
		viewModel.bool <==> switchView.rx.isOn
		viewModel.color ==> (self, ViewController.setTint)
		//or viewModel.color ==> rx.weak(method: ViewController.setTint)
		//or viewModel.color ==> {[weak self] in self?.setTint(color: $0) }
	}
	
	private func setTint(color: UIColor) {
		...
	} 
	...
}
```
	
## Usage

 1. Operator `=>` 
	1. From `ObservableType` to `ObserverType`, creates a subscription and returns `Disposable`:
	 ```swift
	let disposable = intObservable => intObserver
	```
	 2. From `Disposable` to `DisposeBag`:
	 ```swift
	someDisposable => disposeBag
	someObservable => someObserver => disposeBag
	```
	 3. From `ObservableType` to `SchedulerType`, returns `Observable<E>`:
	 ```swift
	let scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "Scheduler")
	someObservable => scheduler => someObserver => disposeBag
	```
 2. Operator `==>`
	Drive `ObservableType` to `ObserverType` on main queue and returns `Disposable`:
	 ```swift
	intObservable ==> intObserver => disposeBag
	```
3. Operators `<=>` and `<==>` create bidirectional subscriptions for `Equatable` sequences
4. `DisposableObserverType` and `DisposableObservableType` - protocols for observer and observeables that dispose all subscriptions on deinit, so you don't have to control disposing for each subscription.
5. `ValueSubject<Element>` - analog of `Variable<Element>` with `DisposeBag` inside.
6. Some features:
		- `skipNil()` operator
		- `compactMap()` operator
		- use `+` and `+=` operator for merging observables, creating disposables, etc

## Installation

RxOperators is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:
```ruby
pod 'RxOperators'
```
and run `pod update` from the podfile directory first.

## Author

Voidilov, voidilov@gmail.com

## License

RxOperators is available under the MIT license. See the LICENSE file for more info.
