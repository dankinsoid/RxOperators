//
//  UIKit++.swift
//  TestProject
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import UIKit
import VDKit
import RxSwift
import RxCocoa

extension ObservableConvertibleType {
	
	public func asDriver() -> Driver<Element> {
		asDriver(onErrorDriveWith: .never())
	}
	
}

extension Reactive where Base: UIResponder {
	
	public var isFirstResponder: ControlProperty<Bool> {
		ControlProperty(
			values: Observable
				.merge(
					methodInvoked(#selector(UIResponder.becomeFirstResponder)),
					methodInvoked(#selector(UIResponder.resignFirstResponder))
				)
				.map { [weak view = self.base] _ in
					view?.isFirstResponder ?? false
				}
				.startWith(base.isFirstResponder)
				.distinctUntilChanged()
				.share(replay: 1),
			valueSink: AnyObserver {[weak base] in
				guard case .next(let value) = $0 else { return }
				if value {
					base?.becomeFirstResponder()
				} else {
					base?.resignFirstResponder()
				}
			}
		)
	}
	
}

extension Reactive where Base: UISearchBar {
	
	public var changes: ControlEvent<String> {
		let first = text.map { $0 ?? "" }
		let second = textDidEndEditing.map {[weak base] in base?.text ?? "" }
		let third = cancelButtonClicked.map { "" }
		return ControlEvent(events: Observable.merge(first, second, third))
	}
	
}

extension Reactive where Base: UIButton {
	
	public func update(animated: Bool = true) -> Binder<ButtonProperties> {
		let updates: (Base, ButtonProperties) -> () = { target, properties in
			target.setTitle(properties.title, for: .normal)
			target.setImage(properties.icon, for: .normal)
			target.isEnabled = properties.isEnabled
		}
		if animated {
			return Binder(base, binding: updates)
		} else {
			return Binder(base) { target, properties in
				UIView.performWithoutAnimation {
					updates(target, properties)
					target.layoutIfNeeded()
				}
			}
		}
	}
	
}

extension Reactive where Base: UIStackView {
	
	public func update<T, V: UIView>(create: @escaping () -> V, update: @escaping (T, V, Int) -> Void) -> Binder<[T]> {
		Binder(base) {
			$0.update(items: $1, create: create, update: update)
		}
	}
	
	public func update<T, V: UIView>(create: @escaping () -> V, update: @escaping (V) -> AnyObserver<T>) -> Binder<[T]> {
		self.update(create: create) { value, view, _ in
			update(view).onNext(value)
		}
	}
	
	public func update<V: UIView & ViewProtocol>(create: @escaping () -> V) -> Binder<[V.Properties]> {
		update(create: create) { value, view, _ in
			view.set(state: value)
		}
	}
	
}

extension Reactive where Base: UIView {
	
	public var id: Binder<String?> {
		self[\.accessibilityIdentifier]
	}
	
}

